import 'package:dio/dio.dart';
import '../core/utils/log_service.dart';
import '../core/utils/retry_interceptor.dart';

/// Precio en caché con timestamp
class _CachedPrice {
  final double price;
  final DateTime timestamp;
  
  _CachedPrice(this.price, this.timestamp);
  
  bool get isExpired => DateTime.now().difference(timestamp).inMinutes > 5;
}

/// Servicio de cotizaciones en tiempo real
/// 
/// Obtiene precios actualizados de acciones, criptomonedas y otros activos
/// usando APIs públicas gratuitas. Implementa singleton y caché.
class PriceService {
  // Singleton
  static final PriceService _instance = PriceService._internal();
  factory PriceService() => _instance;
  
  late final Dio _dio;
  final Map<String, _CachedPrice> _priceCache = {};
  
  PriceService._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    )..interceptors.add(RetryInterceptor(
        dio: Dio(),
        retries: 2,
        retryDelays: const [Duration(seconds: 1), Duration(seconds: 2)],
      ));
  }

  // ============ APIs Disponibles ============
  
  /// API para criptomonedas - CoinGecko (sin API key)
  static const String _coingeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  
  /// API para acciones - Alpha Vantage (requiere API key gratuita)
  static const String _alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  
  /// API alternativa para acciones - Yahoo Finance (sin API key)
  static const String _yahooFinanceBaseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';

  // ============ Obtener Precio de Criptomonedas ============

  /// Obtiene el precio actual de una criptomoneda
  /// 
  /// [symbol] - Símbolo de la crypto (BTC, ETH, ADA, etc.)
  /// [vsCurrency] - Moneda de referencia (eur, usd, etc.)
  /// [useCache] - Si usar caché (default: true)
  /// 
  /// Retorna el precio o null si hay error
  Future<double?> getCryptoPrice(String symbol, {String vsCurrency = 'eur', bool useCache = true}) async {
    try {
      // Verificar caché
      final cacheKey = '${symbol}_$vsCurrency';
      if (useCache && _priceCache.containsKey(cacheKey)) {
        final cached = _priceCache[cacheKey]!;
        if (!cached.isExpired) {
          return cached.price;
        }
      }
      
      // Convertir símbolo a ID de CoinGecko
      final cryptoId = _getCryptoId(symbol);
      
      final response = await _dio.get(
        '$_coingeckoBaseUrl/simple/price',
        queryParameters: {
          'ids': cryptoId,
          'vs_currencies': vsCurrency,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey(cryptoId)) {
          final priceData = data[cryptoId] as Map<String, dynamic>;
          final price = (priceData[vsCurrency] as num?)?.toDouble();
          if (price != null && useCache) {
            _priceCache[cacheKey] = _CachedPrice(price, DateTime.now());
          }
          return price;
        }
      }
      
      return null;
    } catch (e) {
      LogService.error('Error al obtener precio de crypto', e, null, 'PriceService');
      return null;
    }
  }

  /// Obtiene precios de múltiples criptomonedas
  Future<Map<String, double>> getMultipleCryptoPrices(
    List<String> symbols, {
    String vsCurrency = 'eur',
  }) async {
    try {
      final cryptoIds = symbols.map(_getCryptoId).toList();
      final idsString = cryptoIds.join(',');
      
      final response = await _dio.get(
        '$_coingeckoBaseUrl/simple/price',
        queryParameters: {
          'ids': idsString,
          'vs_currencies': vsCurrency,
        },
      );

      final Map<String, double> prices = {};
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        for (int i = 0; i < cryptoIds.length; i++) {
          final cryptoId = cryptoIds[i];
          final symbol = symbols[i];
          
          if (data.containsKey(cryptoId)) {
            final priceData = data[cryptoId] as Map<String, dynamic>;
            final price = (priceData[vsCurrency] as num?)?.toDouble();
            if (price != null) {
              prices[symbol] = price;
            }
          }
        }
      }
      
      return prices;
    } catch (e) {
      LogService.error('Error al obtener múltiples precios', e, null, 'PriceService');
      return {};
    }
  }

  // ============ Obtener Precio de Acciones ============

  /// Obtiene el precio actual de una acción usando Yahoo Finance
  /// 
  /// [symbol] - Ticker de la acción (AAPL, GOOGL, TSLA, etc.)
  /// 
  /// Retorna el precio o null si hay error
  Future<double?> getStockPrice(String symbol) async {
    try {
      // Yahoo Finance requiere el símbolo completo (ej: AAPL para Apple)
      final response = await _dio.get(
        '$_yahooFinanceBaseUrl/$symbol',
        queryParameters: {
          'interval': '1d',
          'range': '1d',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final chart = data['chart'] as Map<String, dynamic>?;
        
        if (chart != null) {
          final result = (chart['result'] as List?)?.first as Map<String, dynamic>?;
          if (result != null) {
            final meta = result['meta'] as Map<String, dynamic>?;
            final regularMarketPrice = meta?['regularMarketPrice'] as num?;
            
            return regularMarketPrice?.toDouble();
          }
        }
      }
      
      return null;
    } catch (e) {
      LogService.error('Error al obtener precio de acción', e, null, 'PriceService');
      return null;
    }
  }

  /// Obtiene el precio de una acción usando Alpha Vantage (con API key)
  /// 
  /// Requiere una API key gratuita de: https://www.alphavantage.co/support/#api-key
  Future<double?> getStockPriceAlphaVantage(String symbol, String apiKey) async {
    try {
      final response = await _dio.get(
        _alphaVantageBaseUrl,
        queryParameters: {
          'function': 'GLOBAL_QUOTE',
          'symbol': symbol,
          'apikey': apiKey,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final globalQuote = data['Global Quote'] as Map<String, dynamic>?;
        
        if (globalQuote != null) {
          final priceString = globalQuote['05. price'] as String?;
          return priceString != null ? double.tryParse(priceString) : null;
        }
      }
      
      return null;
    } catch (e) {
      LogService.error('Error al obtener precio con Alpha Vantage', e, null, 'PriceService');
      return null;
    }
  }

  // ============ Obtener Precio Genérico ============

  /// Obtiene el precio de un activo automáticamente según su tipo
  /// 
  /// [type] - Tipo de inversión (Acciones, Criptomonedas, ETFs, etc.)
  /// [symbol] - Símbolo del activo
  /// [apiKey] - API key opcional para Alpha Vantage
  Future<double?> getAssetPrice(
    String type,
    String symbol, {
    String? apiKey,
  }) async {
    final typeNormalized = type.toLowerCase();
    
    if (typeNormalized.contains('cripto') || 
        typeNormalized.contains('crypto') ||
        typeNormalized.contains('bitcoin') ||
        typeNormalized.contains('ethereum')) {
      return await getCryptoPrice(symbol);
    } else if (typeNormalized.contains('accion') ||
               typeNormalized.contains('stock') ||
               typeNormalized.contains('etf')) {
      // Intentar primero con Yahoo Finance (sin API key)
      final price = await getStockPrice(symbol);
      
      // Si falla y tenemos API key, intentar con Alpha Vantage
      if (price == null && apiKey != null) {
        return await getStockPriceAlphaVantage(symbol, apiKey);
      }
      
      return price;
    } else {
      // Para otros tipos, retornar null (actualización manual)
      return null;
    }
  }

  /// Calcula el valor actual de una inversión
  /// 
  /// [amountInvested] - Cantidad invertida
  /// [initialPrice] - Precio al que se compró
  /// [currentPrice] - Precio actual
  /// 
  /// Ejemplo: Invertiste 1000€ cuando BTC estaba a 20.000€
  ///          Ahora BTC está a 40.000€
  ///          Valor actual = 1000 * (40000 / 20000) = 2000€
  double calculateCurrentValue({
    required double amountInvested,
    required double initialPrice,
    required double currentPrice,
  }) {
    if (initialPrice <= 0) return amountInvested;
    
    final priceRatio = currentPrice / initialPrice;
    return amountInvested * priceRatio;
  }

  // ============ Mapeo de Símbolos a IDs ============

  /// Convierte símbolos comunes de crypto a IDs de CoinGecko
  String _getCryptoId(String symbol) {
    final symbolUpper = symbol.toUpperCase();
    
    const Map<String, String> cryptoIdMap = {
      'BTC': 'bitcoin',
      'BITCOIN': 'bitcoin',
      'ETH': 'ethereum',
      'ETHEREUM': 'ethereum',
      'USDT': 'tether',
      'TETHER': 'tether',
      'BNB': 'binancecoin',
      'BINANCE': 'binancecoin',
      'SOL': 'solana',
      'SOLANA': 'solana',
      'ADA': 'cardano',
      'CARDANO': 'cardano',
      'XRP': 'ripple',
      'RIPPLE': 'ripple',
      'DOGE': 'dogecoin',
      'DOGECOIN': 'dogecoin',
      'DOT': 'polkadot',
      'POLKADOT': 'polkadot',
      'MATIC': 'matic-network',
      'POLYGON': 'matic-network',
      'SHIB': 'shiba-inu',
      'SHIBA': 'shiba-inu',
      'AVAX': 'avalanche-2',
      'AVALANCHE': 'avalanche-2',
      'LINK': 'chainlink',
      'CHAINLINK': 'chainlink',
      'UNI': 'uniswap',
      'UNISWAP': 'uniswap',
      'LTC': 'litecoin',
      'LITECOIN': 'litecoin',
      'ATOM': 'cosmos',
      'COSMOS': 'cosmos',
      'XLM': 'stellar',
      'STELLAR': 'stellar',
      'XMR': 'monero',
      'MONERO': 'monero',
    };

    return cryptoIdMap[symbolUpper] ?? symbolUpper.toLowerCase();
  }

  /// Verifica si un tipo de activo soporta actualización automática
  bool supportsAutomaticUpdate(String type) {
    final typeNormalized = type.toLowerCase();
    
    return typeNormalized.contains('cripto') ||
           typeNormalized.contains('crypto') ||
           typeNormalized.contains('accion') ||
           typeNormalized.contains('stock') ||
           typeNormalized.contains('etf');
  }

  /// Libera recursos
  void dispose() {
    _dio.close();
  }
}
