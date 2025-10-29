"""
Aplicación Flask para servir el modelo de AI
"""
from flask import Flask, request, jsonify
from model import SentimentModel
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Inicializar Flask
app = Flask(__name__)

# Inicializar modelo
logger.info("Inicializando modelo de AI...")
sentiment_model = SentimentModel()
logger.info("✓ Modelo inicializado correctamente")

@app.route('/')
def home():
    """Endpoint raíz"""
    return jsonify({
        'status': 'online',
        'service': 'AI Sentiment Analysis API',
        'version': '1.0.0',
        'endpoints': {
            'health': '/health',
            'predict': '/api/predict (POST)'
        }
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': sentiment_model.model is not None
    }), 200

@app.route('/api/predict', methods=['POST'])
def predict():
    """Endpoint para realizar predicciones"""
    try:
        # Validar request
        if not request.is_json:
            return jsonify({'error': 'Content-Type debe ser application/json'}), 400
        
        data = request.get_json()
        
        if 'text' not in data:
            return jsonify({'error': 'Campo "text" es requerido'}), 400
        
        text = data['text']
        
        if not isinstance(text, str) or len(text.strip()) == 0:
            return jsonify({'error': 'El texto debe ser una cadena no vacía'}), 400
        
        # Realizar predicción
        logger.info(f"Procesando texto: {text[:50]}...")
        result = sentiment_model.predict(text)
        
        return jsonify({
            'success': True,
            'input': text,
            'result': result
        }), 200
        
    except Exception as e:
        logger.error(f"Error en predicción: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    # En producción, usar gunicorn en lugar de Flask development server
    app.run(host='0.0.0.0', port=8000, debug=False)
