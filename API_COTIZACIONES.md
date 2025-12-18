# 📡 API de Cotizaciones - Guía de Uso

## 🎯 Funcionalidad Implementada

La aplicación ahora puede **actualizar automáticamente** el valor de tus inversiones consultando APIs financieras en tiempo real.

---

## ✅ Activos Soportados

### 🪙 Criptomonedas (API: CoinGecko - SIN API Key necesaria)
- Bitcoin (BTC)
- Ethereum (ETH)
- Tether (USDT)
- Binance Coin (BNB)
- Solana (SOL)
- Cardano (ADA)
- Ripple (XRP)
- Dogecoin (DOGE)
- Polkadot (DOT)
- Polygon (MATIC)
- Shiba Inu (SHIB)
- Avalanche (AVAX)
- Chainlink (LINK)
- Uniswap (UNI)
- Litecoin (LTC)
- Cosmos (ATOM)
- Stellar (XLM)
- Monero (XMR)
- **Y muchas más...**

### 📈 Acciones y ETFs (API: Yahoo Finance - SIN API Key)
- Acciones de cualquier bolsa mundial
- ETFs
- Índices

**Ejemplos de símbolos:**
- Apple: `AAPL`
- Google: `GOOGL`
- Tesla: `TSLA`
- Amazon: `AMZN`
- Microsoft: `MSFT`
- S&P 500 ETF: `SPY`
- Nasdaq ETF: `QQQ`

---

## 🚀 Cómo Usar

### 1️⃣ Actualizar UNA inversión específica

1. Ve a **"Mis Inversiones"**
2. Toca el menú `⋮` de la inversión que quieres actualizar
3. Selecciona **"Actualizar Precio"**
4. El precio se actualizará automáticamente desde la API

### 2️⃣ Actualizar TODAS las inversiones

1. Ve a **"Mis Inversiones"**
2. Toca el icono de **"Actualizar"** `🔄` en la parte superior derecha
3. Todas las inversiones compatibles se actualizarán automáticamente

---

## 📝 Requisitos para Actualización Automática

### ✅ Para Criptomonedas:
- **Tipo**: Debe ser "Criptomonedas"
- **Nombre**: Usa el símbolo estándar (BTC, ETH, SOL, etc.)
- **Sin configuración adicional**

### ✅ Para Acciones:
- **Tipo**: Debe ser "Acciones" o "ETFs"
- **Nombre**: Usa el ticker bursátil (AAPL, GOOGL, TSLA, etc.)
- **Sin configuración adicional** (usa Yahoo Finance)

### ⚠️ Para Acciones con Alpha Vantage (Opcional):
Si Yahoo Finance no funciona, puedes usar Alpha Vantage:

1. Obtén una API key gratuita: https://www.alphavantage.co/support/#api-key
2. La app la usará automáticamente como fallback

---

## 🔄 Cambio Importante: Balance Corregido

### ❌ Antes (Incorrecto):
```
Tienes 50€
Inviertes 50€ en Bitcoin
Balance: 50€ + 50€ - 0€ = 100€ ❌
```

### ✅ Ahora (Correcto):
```
Tienes 50€
Inviertes 50€ en Bitcoin
Balance: 50€ - 0€ - 50€ = 0€ ✅
```

**Explicación**: Cuando inviertes dinero, ese dinero **sale de tu cartera** (como un gasto), aunque sigue siendo tuyo en forma de inversión.

---

## 🎨 Ejemplo de Uso Completo

### Escenario: Invertir en Bitcoin

1. **Crear la inversión**:
   - Tipo: `Criptomonedas`
   - Nombre: `BTC`
   - Monto invertido: `500€`
   - Valor actual: `500€` (inicial)

2. **La app calcula**:
   - Precio de Bitcoin al invertir: digamos 40.000€
   - Cantidad de BTC comprada: 0.0125 BTC

3. **Actualizar precio automáticamente**:
   - Toca "Actualizar Precio"
   - La app consulta el precio actual de BTC: 45.000€
   - Calcula nuevo valor: 0.0125 × 45.000 = 562.50€
   - Ganancia: +62.50€ (+12.5%)

---

## 🔧 APIs Utilizadas

### 1. CoinGecko (Criptomonedas)
- **URL**: https://api.coingecko.com/api/v3
- **Límite**: Sin límite estricto para uso gratuito
- **API Key**: No necesaria
- **Moneda**: EUR (euros) por defecto

### 2. Yahoo Finance (Acciones/ETFs)
- **URL**: https://query1.finance.yahoo.com
- **Límite**: Sin límite conocido
- **API Key**: No necesaria
- **Alcance**: Mercados globales

### 3. Alpha Vantage (Acciones - Fallback)
- **URL**: https://www.alphavantage.co
- **Límite**: 25 llamadas por día (gratis)
- **API Key**: Requerida (gratuita)
- **Uso**: Automático como fallback si Yahoo falla

---

## 📊 Inversiones NO Automáticas

Estos tipos de inversión requieren **actualización manual**:
- Fondos de Inversión
- Bonos
- Bienes Raíces
- Otros

Para actualizarlas:
1. Ve a "Mis Inversiones"
2. Toca el menú `⋮` → "Editar"
3. Cambia el "Valor Actual" manualmente

---

## 🛡️ Privacidad y Seguridad

✅ **Sin datos personales**: Solo se envían símbolos de activos  
✅ **Sin registro**: No se requiere cuenta en las APIs  
✅ **Offline primero**: Las APIs solo se usan cuando actualizas manualmente  
✅ **Sin tracking**: Las APIs públicas no rastrean usuarios  

---

## 🐛 Solución de Problemas

### "No se pudo actualizar el precio"

**Causas posibles**:
1. Sin conexión a internet
2. Símbolo incorrecto (verifica el ticker)
3. API temporalmente caída
4. Tipo de activo no soportado

**Soluciones**:
- Verifica tu conexión
- Confirma el símbolo (ej: `BTC` no `Bitcoin`)
- Espera unos minutos y reintenta
- Actualiza manualmente si es necesario

---

## 💡 Tips y Mejores Prácticas

1. **Usa símbolos estándar**: 
   - ✅ `BTC` en lugar de `Bitcoin`
   - ✅ `AAPL` en lugar de `Apple`

2. **Actualiza periódicamente**:
   - Cryptos: Cada hora o día (muy volátiles)
   - Acciones: Una vez al día (después del cierre)

3. **No actualices excesivamente**:
   - Las APIs tienen límites
   - Una vez al día es suficiente para la mayoría

4. **Tipo correcto**:
   - Asegúrate de seleccionar el tipo adecuado al crear la inversión

---

## 📈 Próximas Mejoras Planificadas

- [ ] Actualización automática programada (diaria)
- [ ] Historial de precios con gráfico
- [ ] Alertas de cambios significativos
- [ ] Más APIs (Binance, Kraken, etc.)
- [ ] Soporte para más tipos de activos

---

**¡Disfruta de tus inversiones actualizadas automáticamente!** 🚀
