# Guide de Configuration API Gemini

## 🛠️ Configuration dans Xcode

### Méthode 1: Variable d'Environnement (Recommandée)

1. **Ouvrir Xcode** avec le projet Muorz
2. **Menu** : `Product` → `Scheme` → `Edit Scheme...`
3. **Sélectionner "Run"** dans la barre latérale gauche
4. **Onglet "Arguments"**
5. **Section "Environment Variables"** → cliquer `+`
6. **Ajouter** :
   - **Name** : `GEMINI_API_KEY`
   - **Value** : `[VOTRE_CLE_API_GEMINI]`
7. **Fermer** la fenêtre

### Méthode 2: Info.plist (Alternative)

1. **Ouvrir Info.plist** dans Xcode
2. **Clic droit** → `Add Row`
3. **Ajouter** :
   - **Key** : `GEMINI_API_KEY`
   - **Type** : `String`
   - **Value** : `[VOTRE_CLE_API_GEMINI]`

## 🧪 Vérification de la Configuration

### Messages de Console à Surveiller

#### ✅ Configuration Réussie
```
🚀 Attempting Gemini API call (attempt 1/3)
🌐 API Request: [détails]
📡 API Response: [réponse]
✅ Successfully processed menu with X items
```

#### ❌ Configuration Échouée
```
⚠️ No Gemini API key configured, using sample data
```

#### 🔧 Erreurs API
```
❌ Gemini API Error: [message d'erreur]
```

## 🎯 Test de l'API

### Flux de Test
1. **Lancer l'app** en mode Debug
2. **Ouvrir la console** Xcode (View → Debug Area → Console)
3. **Prendre une photo** d'un menu
4. **Observer les messages** de debug
5. **Vérifier** que les données sont structurées

### Résultat Attendu
- ✅ Traitement des menus réels via Gemini
- ✅ Traductions automatiques
- ✅ Scores nutritionnels inférés
- ✅ Tags diététiques détectés
- ✅ Catégorisation intelligente

## 🔒 Sécurité

### ⚠️ Bonnes Pratiques
- **Jamais de commit** de clés API dans Git
- **Variables d'environnement** pour le développement
- **Info.plist** ajouté au .gitignore
- **Vérification régulière** des commits

### Commande de Vérification
```bash
# Vérifier qu'aucune clé n'est trackée
git grep -r "AIzaSy" .
```

## 🚨 Dépannage

### Problèmes Courants

#### API Key Non Reconnue
- Vérifier l'orthographe : `GEMINI_API_KEY`
- Redémarrer Xcode après configuration
- Vérifier que la clé est active sur Google AI Studio

#### Erreurs de Réseau
- Vérifier la connexion internet
- Contrôler les quotas API sur Google Cloud
- Tester avec `USE_MOCK_SERVICE=true`

#### Erreurs de Parsing JSON
- Activer le logging détaillé
- Vérifier la réponse brute dans la console
- Tester avec différents types de menus

### Mode Debug Avancé

Pour activer le logging détaillé :
```swift
// Dans APIConfiguration.swift
static let enableAPILogging = true
```

### Mode Mock pour Tests

Pour forcer l'utilisation du service mock :
```
Environment Variable: USE_MOCK_SERVICE=true
```

## 📞 Support

En cas de problème persistant :
1. **Console Xcode** : Copier les messages d'erreur
2. **Test Mock** : Vérifier que l'app fonctionne en mode mock
3. **Google AI Studio** : Vérifier l'état de la clé API
4. **Quotas** : Contrôler les limites d'utilisation

## 🎉 Succès !

Une fois configurée correctement, l'app devrait :
- 📸 Traiter les photos de menus
- 🤖 Utiliser l'IA Gemini pour l'analyse
- 📋 Afficher des menus structurés
- 🔍 Permettre la recherche et le filtrage
- 🏷️ Afficher les informations nutritionnelles 