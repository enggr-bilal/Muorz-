#!/bin/bash

# Script de vérification de la configuration Muorz
echo "🔍 Vérification de la configuration Muorz..."
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "README.md" ] || [ ! -d "Muorz" ]; then
    echo "❌ Erreur: Ce script doit être exécuté depuis la racine du projet Muorz"
    exit 1
fi

echo "✅ Répertoire du projet détecté"

# Vérifier la structure des fichiers
echo ""
echo "📁 Vérification de la structure des fichiers..."

required_files=(
    "README.md"
    "API_CONFIGURATION_GUIDE.md"
    ".gitignore"
    "Muorz/Model/MenuItem.swift"
    "Muorz/ViewModel/MenuService.swift"
    "Muorz/ViewModel/APIConfiguration.swift"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (manquant)"
    fi
done

# Vérifier que les clés API ne sont pas dans Git
echo ""
echo "🔒 Vérification de sécurité..."

if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "✅ Dépôt Git détecté"
    
    # Chercher des clés API potentielles
    api_keys_found=$(git grep -r "AIzaSy" . 2>/dev/null || true)
    
    if [ -z "$api_keys_found" ]; then
        echo "✅ Aucune clé API trouvée dans Git"
    else
        echo "⚠️  Clés API potentielles détectées dans Git:"
        echo "$api_keys_found"
        echo ""
        echo "🚨 ATTENTION: Supprimez ces clés avant de commiter!"
    fi
else
    echo "⚠️  Pas de dépôt Git détecté"
fi

# Vérifier le .gitignore
echo ""
echo "🛡️  Vérification du .gitignore..."

if grep -q "API_SETUP_INSTRUCTIONS.md" .gitignore 2>/dev/null; then
    echo "✅ Fichiers sensibles protégés dans .gitignore"
else
    echo "⚠️  .gitignore pourrait ne pas protéger tous les fichiers sensibles"
fi

# Instructions finales
echo ""
echo "🎯 Prochaines étapes:"
echo "1. Ouvrir Xcode avec le projet Muorz"
echo "2. Configurer la variable d'environnement GEMINI_API_KEY"
echo "3. Lancer l'app et vérifier la console pour les messages API"
echo ""
echo "📖 Guide détaillé: API_CONFIGURATION_GUIDE.md"
echo ""
echo "✨ Configuration terminée! Votre app Muorz est prête à utiliser l'API Gemini." 