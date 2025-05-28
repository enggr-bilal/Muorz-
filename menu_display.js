const menuData = [
  {
    "original_name": "INVOLTINI DE SPECK",
    "translated_name": "Speck Rolls",
    "ingredients_en": ["speck ham", "ricotta"],
    "category_en": "starter",
    "price": null,
    "nutrition_scores": {
      "protein": 7,
      "fat": 8,
      "carbs": 2
    },
    "tags": {
      "vegetarian": false,
      "vegan": false,
      "gluten_free": true,
      "dairy_free": false
    }
  },
  {
    "original_name": "MINI POIVRONS FARCIS AU THON",
    "translated_name": "Mini Peppers Stuffed with Tuna",
    "ingredients_en": ["mini peppers", "tuna", "olive oil", "herbs"],
    "category_en": "starter",
    "price": "5,00 €",
    "nutrition_scores": {
      "protein": 6,
      "fat": 5,
      "carbs": 2
    },
    "tags": {
      "vegetarian": false,
      "vegan": false,
      "gluten_free": true,
      "dairy_free": true
    }
  },
  {
    "original_name": "BRUSCHETTA VEGETARIANA",
    "translated_name": "Vegetarian Bruschetta",
    "ingredients_en": ["tomato coulis", "eggplants", "sun-dried tomatoes", "mushrooms", "bell peppers", "mozzarella", "bread"],
    "category_en": "starter",
    "price": null,
    "nutrition_scores": {
      "protein": 4,
      "fat": 5,
      "carbs": 7
    },
    "tags": {
      "vegetarian": true,
      "vegan": false,
      "gluten_free": false,
      "dairy_free": false
    }
  },
  {
    "original_name": "PIZZA VEGETARIANA",
    "translated_name": "Vegetarian Pizza",
    "ingredients_en": ["tomato coulis", "mushrooms", "tomatoes", "bell peppers", "artichokes", "eggplants", "mozzarella", "oregano"],
    "category_en": "main course",
    "price": "12,00 €",
    "nutrition_scores": {
      "protein": 5,
      "fat": 6,
      "carbs": 7
    },
    "tags": {
      "vegetarian": true,
      "vegan": false,
      "gluten_free": false,
      "dairy_free": false
    }
  },
  {
    "original_name": "PASTA ALLA BOLOGNESE",
    "translated_name": "Bolognese Pasta",
    "ingredients_en": ["tomato sauce", "ground beef", "tomatoes", "onions", "pasta"],
    "category_en": "main course",
    "price": "7,50 €",
    "nutrition_scores": {
      "protein": 6,
      "fat": 6,
      "carbs": 7
    },
    "tags": {
      "vegetarian": false,
      "vegan": false,
      "gluten_free": false,
      "dairy_free": true
    }
  },
  {
    "original_name": "LASAGNE VEGETARIANA",
    "translated_name": "Vegetarian Lasagna",
    "ingredients_en": ["pasta", "béchamel", "crème fraîche", "eggplants", "tomatoes", "zucchini", "onions", "pesto", "mozzarella"],
    "category_en": "main course",
    "price": "9,00 €",
    "nutrition_scores": {
      "protein": 6,
      "fat": 7,
      "carbs": 6
    },
    "tags": {
      "vegetarian": true,
      "vegan": false,
      "gluten_free": false,
      "dairy_free": false
    }
  },
  {
    "original_name": "PANNA COTTA FRUITS ROUGES",
    "translated_name": "Panna Cotta with Red Fruits",
    "ingredients_en": ["cream", "sugar", "gelatin", "red fruit coulis"],
    "category_en": "dessert",
    "price": "4,00 €",
    "nutrition_scores": {
      "protein": 2,
      "fat": 7,
      "carbs": 6
    },
    "tags": {
      "vegetarian": true,
      "vegan": false,
      "gluten_free": true,
      "dairy_free": false
    }
  },
  {
    "original_name": "TIRAMISU",
    "translated_name": "Tiramisu",
    "ingredients_en": ["ladyfingers", "mascarpone", "coffee", "sugar", "eggs", "cocoa powder"],
    "category_en": "dessert",
    "price": "4,00 €",
    "nutrition_scores": {
      "protein": 4,
      "fat": 7,
      "carbs": 6
    },
    "tags": {
      "vegetarian": true,
      "vegan": false,
      "gluten_free": false,
      "dairy_free": false
    }
  },
];

// Group the menu items by category
const groupedMenu = menuData.reduce((acc, item) => {
  if (!acc[item.category_en]) {
    acc[item.category_en] = [];
  }
  acc[item.category_en].push({
    name: item.translated_name,
    ingredients: item.ingredients_en,
    price: item.price || 'N/A'
  });
  return acc;
}, {});

// Display the grouped menu
console.log('Menu by Category:\n');

Object.entries(groupedMenu).forEach(([category, items]) => {
  console.log(`\n${category.toUpperCase()}:\n`);
  items.forEach(item => {
    console.log(`- ${item.name}`);
    console.log(`  Ingredients: ${item.ingredients.join(', ')}`);
    console.log(`  Price: ${item.price}\n`);
  });
}); 
