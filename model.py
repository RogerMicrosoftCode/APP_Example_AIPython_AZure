"""
Módulo para el modelo de Machine Learning
"""
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import joblib
import os

class SentimentModel:
    def __init__(self):
        self.model = None
        self.load_or_train_model()
    
    def load_or_train_model(self):
        """Carga o entrena el modelo de sentimiento"""
        model_path = 'sentiment_model.pkl'
        
        if os.path.exists(model_path):
            self.model = joblib.load(model_path)
            print("✓ Modelo cargado desde archivo")
        else:
            print("⚙ Entrenando nuevo modelo...")
            self.train_model()
            joblib.dump(self.model, model_path)
            print("✓ Modelo entrenado y guardado")
    
    def train_model(self):
        """Entrena un modelo simple de clasificación de sentimientos"""
        # Datos de ejemplo para entrenamiento
        texts = [
            "Me encanta este producto, es excelente",
            "Muy buena calidad, lo recomiendo",
            "Fantástico servicio al cliente",
            "Terrible experiencia, no lo recomiendo",
            "Muy mala calidad, decepcionante",
            "Pésimo servicio, nunca más",
            "Es aceptable, nada especial",
            "Cumple su función básica"
        ]
        
        labels = [
            "positivo", "positivo", "positivo",
            "negativo", "negativo", "negativo",
            "neutral", "neutral"
        ]
        
        # Crear pipeline con TF-IDF y Naive Bayes
        self.model = Pipeline([
            ('tfidf', TfidfVectorizer(max_features=100)),
            ('classifier', MultinomialNB())
        ])
        
        self.model.fit(texts, labels)
    
    def predict(self, text):
        """Predice el sentimiento de un texto"""
        if self.model is None:
            raise ValueError("Modelo no inicializado")
        
        prediction = self.model.predict([text])[0]
        probabilities = self.model.predict_proba([text])[0]
        
        # Obtener las clases y sus probabilidades
        classes = self.model.classes_
        prob_dict = {cls: float(prob) for cls, prob in zip(classes, probabilities)}
        
        return {
            'prediction': prediction,
            'confidence': float(max(probabilities)),
            'probabilities': prob_dict
        }
