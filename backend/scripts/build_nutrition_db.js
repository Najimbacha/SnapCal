require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const fs = require('fs');
const path = require('path');

const USDA_API_KEY = process.env.USDA_API_KEY;
const USDA_SEARCH_URL = 'https://api.nal.usda.gov/fdc/v1/foods/search';

const CATEGORIES = {
  meats: { start: 1, query: 'beef chicken pork lamb turkey ham bacon sausage' },
  seafood: { start: 101, query: 'salmon tuna shrimp cod tilapia mackerel sardine trout fish' },
  vegetables: { start: 151, query: 'broccoli spinach carrot tomato lettuce cucumber onion pepper cabbage kale celery mushroom corn potato sweet potato' },
  fruits: { start: 251, query: 'apple banana orange strawberry grape blueberry mango pineapple watermelon kiwi peach pear plum cherry lemon lime avocado' },
  grains: { start: 301, query: 'rice pasta bread oats quinoa barley couscous tortilla naan cereal pancake waffle' },
  dairy: { start: 351, query: 'milk cheese yogurt butter egg cream cottage cheese sour cream' },
  legumes_nuts: { start: 401, query: 'beans lentils chickpeas tofu peanut almond walnut cashew pistachio sunflower seed' },
  fats_oils: { start: 421, query: 'olive oil coconut oil canola oil sesame oil mayonnaise vinaigrette' },
  drinks: { start: 441, query: 'water coffee tea juice soda milk smoothie' },
  desserts: { start: 461, query: 'cake cookie ice cream chocolate pudding pastry donut brownie' },
  fast_food: { start: 481, query: 'pizza hamburger fries sandwich wrap taco burrito hot dog nuggets' },
  international: { start: 531, query: 'curry biryani sushi ramen dumpling stir fry falafel hummus pita naan taco paella risotto' },
};

const BASE_FOODS = [
  { id: 'FDB_000001', display_name: 'Beef, ground, 80% lean, cooked', category: 'meats', calories: 254, protein: 26, carbs: 0, fat: 17, tags: ['beef', 'ground beef', 'mince', 'hamburger meat'] },
  { id: 'FDB_000002', display_name: 'Beef steak, sirloin, cooked', category: 'meats', calories: 206, protein: 26, carbs: 0, fat: 11, tags: ['steak', 'beef steak', 'sirloin', 'ribeye'] },
  { id: 'FDB_000003', display_name: 'Chicken breast, roasted', category: 'meats', calories: 165, protein: 31, carbs: 0, fat: 3.6, tags: ['chicken', 'chicken breast', 'poultry', 'white meat'] },
  { id: 'FDB_000004', display_name: 'Chicken thigh, roasted', category: 'meats', calories: 209, protein: 26, carbs: 0, fat: 11, tags: ['chicken thigh', 'dark meat', 'chicken leg'] },
  { id: 'FDB_000005', display_name: 'Chicken wing, roasted', category: 'meats', calories: 203, protein: 30, carbs: 0, fat: 8.1, tags: ['chicken wing', 'wings'] },
  { id: 'FDB_000006', display_name: 'Pork chop, cooked', category: 'meats', calories: 231, protein: 25, carbs: 0, fat: 14, tags: ['pork', 'pork chop', 'pork loin'] },
  { id: 'FDB_000007', display_name: 'Pork belly, cooked', category: 'meats', calories: 518, protein: 9, carbs: 0, fat: 53, tags: ['pork belly', 'bacon'] },
  { id: 'FDB_000008', display_name: 'Lamb chop, cooked', category: 'meats', calories: 243, protein: 25, carbs: 0, fat: 16, tags: ['lamb', 'lamb chop', 'mutton'] },
  { id: 'FDB_000009', display_name: 'Turkey breast, roasted', category: 'meats', calories: 135, protein: 30, carbs: 0, fat: 0.7, tags: ['turkey', 'turkey breast', 'poultry'] },
  { id: 'FDB_000010', display_name: 'Bacon, cooked', category: 'meats', calories: 541, protein: 37, carbs: 1.4, fat: 42, tags: ['bacon', 'crispy bacon'] },
  { id: 'FDB_000011', display_name: 'Ham, sliced', category: 'meats', calories: 145, protein: 20, carbs: 1.5, fat: 6, tags: ['ham', 'deli ham', 'sliced ham'] },
  { id: 'FDB_000012', display_name: 'Sausage, cooked', category: 'meats', calories: 326, protein: 14, carbs: 2, fat: 29, tags: ['sausage', 'breakfast sausage', 'bratwurst'] },
  { id: 'FDB_000013', display_name: 'Hot dog, cooked', category: 'meats', calories: 290, protein: 11, carbs: 2, fat: 27, tags: ['hot dog', 'frankfurter', 'wiener'] },
  { id: 'FDB_000014', display_name: 'Beef liver, cooked', category: 'meats', calories: 191, protein: 29, carbs: 5.1, fat: 5.3, tags: ['liver', 'beef liver', 'organ meat'] },
  { id: 'FDB_000015', display_name: 'Chicken liver, cooked', category: 'meats', calories: 172, protein: 27, carbs: 1.3, fat: 6.4, tags: ['chicken liver', 'liver'] },
  { id: 'FDB_000016', display_name: 'Ground turkey, cooked', category: 'meats', calories: 203, protein: 27, carbs: 0, fat: 10, tags: ['ground turkey', 'turkey mince'] },
  { id: 'FDB_000017', display_name: 'Beef ribs, cooked', category: 'meats', calories: 291, protein: 22, carbs: 0, fat: 22, tags: ['ribs', 'beef ribs', 'bbq ribs'] },
  { id: 'FDB_000018', display_name: 'Pork tenderloin, cooked', category: 'meats', calories: 143, protein: 26, carbs: 0, fat: 3.5, tags: ['pork tenderloin', 'pork fillet'] },
  { id: 'FDB_000019', display_name: 'Duck breast, cooked', category: 'meats', calories: 200, protein: 25, carbs: 0, fat: 11, tags: ['duck', 'duck breast'] },
  { id: 'FDB_000020', display_name: 'Veal cutlet, cooked', category: 'meats', calories: 231, protein: 28, carbs: 0, fat: 13, tags: ['veal', 'veal cutlet', 'veal steak'] },
  { id: 'FDB_000021', display_name: 'Beef jerky', category: 'meats', calories: 410, protein: 33, carbs: 22, fat: 25, tags: ['beef jerky', 'jerky', 'dried meat'] },
  { id: 'FDB_000022', display_name: 'Chicken, grilled', category: 'meats', calories: 158, protein: 32, carbs: 0, fat: 3.2, tags: ['grilled chicken', 'chargrilled chicken'] },

  { id: 'FDB_000101', display_name: 'Salmon, cooked', category: 'seafood', calories: 206, protein: 22, carbs: 0, fat: 13, tags: ['salmon', 'fish', 'grilled salmon'] },
  { id: 'FDB_000102', display_name: 'Tuna, canned in water', category: 'seafood', calories: 116, protein: 26, carbs: 0, fat: 0.8, tags: ['tuna', 'canned tuna', 'tuna salad'] },
  { id: 'FDB_000103', display_name: 'Shrimp, cooked', category: 'seafood', calories: 99, protein: 24, carbs: 0.2, fat: 0.3, tags: ['shrimp', 'prawns', 'prawn'] },
  { id: 'FDB_000104', display_name: 'Cod, cooked', category: 'seafood', calories: 105, protein: 23, carbs: 0, fat: 0.9, tags: ['cod', 'white fish', 'fish'] },
  { id: 'FDB_000105', display_name: 'Tilapia, cooked', category: 'seafood', calories: 128, protein: 26, carbs: 0, fat: 2.7, tags: ['tilapia', 'white fish'] },
  { id: 'FDB_000106', display_name: 'Mackerel, cooked', category: 'seafood', calories: 262, protein: 19, carbs: 0, fat: 20, tags: ['mackerel', 'oily fish'] },
  { id: 'FDB_000107', display_name: 'Sardines, canned', category: 'seafood', calories: 208, protein: 25, carbs: 0, fat: 11, tags: ['sardines', 'canned fish'] },
  { id: 'FDB_000108', display_name: 'Trout, cooked', category: 'seafood', calories: 190, protein: 23, carbs: 0, fat: 11, tags: ['trout', 'rainbow trout'] },
  { id: 'FDB_000109', display_name: 'Tuna steak, cooked', category: 'seafood', calories: 184, protein: 30, carbs: 0, fat: 6.1, tags: ['tuna steak', 'fresh tuna'] },
  { id: 'FDB_000110', display_name: 'Catfish, cooked', category: 'seafood', calories: 162, protein: 19, carbs: 0, fat: 9, tags: ['catfish'] },
  { id: 'FDB_000111', display_name: 'Crab, cooked', category: 'seafood', calories: 87, protein: 19, carbs: 0, fat: 0.7, tags: ['crab', 'crab meat'] },
  { id: 'FDB_000112', display_name: 'Lobster, cooked', category: 'seafood', calories: 89, protein: 19, carbs: 0, fat: 0.6, tags: ['lobster'] },
  { id: 'FDB_000113', display_name: 'Clams, cooked', category: 'seafood', calories: 148, protein: 25, carbs: 5.1, fat: 2, tags: ['clams', 'shellfish'] },
  { id: 'FDB_000114', display_name: 'Scallops, cooked', category: 'seafood', calories: 111, protein: 21, carbs: 5.4, fat: 0.8, tags: ['scallops'] },
  { id: 'FDB_000115', display_name: 'Mussels, cooked', category: 'seafood', calories: 172, protein: 24, carbs: 7.4, fat: 4.5, tags: ['mussels'] },
  { id: 'FDB_000116', display_name: 'Halibut, cooked', category: 'seafood', calories: 140, protein: 27, carbs: 0, fat: 3, tags: ['halibut'] },
  { id: 'FDB_000117', display_name: 'Fish fillet, battered, fried', category: 'seafood', calories: 232, protein: 18, carbs: 10, fat: 13, tags: ['fried fish', 'fish and chips', 'fish fillet'] },
  { id: 'FDB_000118', display_name: 'Octopus, cooked', category: 'seafood', calories: 163, protein: 30, carbs: 4.4, fat: 2.1, tags: ['octopus', 'pulpo'] },
  { id: 'FDB_000119', display_name: 'Calamari, fried', category: 'seafood', calories: 175, protein: 15, carbs: 7, fat: 10, tags: ['calamari', 'fried squid', 'squid'] },
  { id: 'FDB_000120', display_name: 'Anchovy, canned', category: 'seafood', calories: 210, protein: 29, carbs: 0, fat: 10, tags: ['anchovy', 'anchovies'] },

  { id: 'FDB_000151', display_name: 'Broccoli, cooked', category: 'vegetables', calories: 35, protein: 2.4, carbs: 7, fat: 0.4, tags: ['broccoli'] },
  { id: 'FDB_000152', display_name: 'Spinach, cooked', category: 'vegetables', calories: 23, protein: 2.9, carbs: 3.8, fat: 0.3, tags: ['spinach'] },
  { id: 'FDB_000153', display_name: 'Spinach, raw', category: 'vegetables', calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, tags: ['spinach', 'salad greens'] },
  { id: 'FDB_000154', display_name: 'Carrot, raw', category: 'vegetables', calories: 41, protein: 0.9, carbs: 10, fat: 0.2, tags: ['carrot', 'carrots'] },
  { id: 'FDB_000155', display_name: 'Tomato, raw', category: 'vegetables', calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, tags: ['tomato', 'tomatoes'] },
  { id: 'FDB_000156', display_name: 'Lettuce, iceberg', category: 'vegetables', calories: 14, protein: 0.9, carbs: 3, fat: 0.1, tags: ['lettuce', 'salad', 'iceberg'] },
  { id: 'FDB_000157', display_name: 'Cucumber, raw', category: 'vegetables', calories: 15, protein: 0.7, carbs: 3.6, fat: 0.1, tags: ['cucumber'] },
  { id: 'FDB_000158', display_name: 'Onion, raw', category: 'vegetables', calories: 40, protein: 1.1, carbs: 9.3, fat: 0.1, tags: ['onion', 'onions'] },
  { id: 'FDB_000159', display_name: 'Bell pepper, red, raw', category: 'vegetables', calories: 31, protein: 1, carbs: 6, fat: 0.3, tags: ['bell pepper', 'capsicum', 'red pepper'] },
  { id: 'FDB_000160', display_name: 'Cabbage, raw', category: 'vegetables', calories: 25, protein: 1.3, carbs: 5.8, fat: 0.1, tags: ['cabbage'] },
  { id: 'FDB_000161', display_name: 'Kale, raw', category: 'vegetables', calories: 49, protein: 4.3, carbs: 8.8, fat: 0.9, tags: ['kale'] },
  { id: 'FDB_000162', display_name: 'Celery, raw', category: 'vegetables', calories: 16, protein: 0.7, carbs: 3.5, fat: 0.2, tags: ['celery'] },
  { id: 'FDB_000163', display_name: 'Mushroom, raw', category: 'vegetables', calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, tags: ['mushroom', 'mushrooms'] },
  { id: 'FDB_000164', display_name: 'Corn, cooked', category: 'vegetables', calories: 96, protein: 3.4, carbs: 21, fat: 1.5, tags: ['corn', 'sweet corn', 'maize'] },
  { id: 'FDB_000165', display_name: 'Potato, boiled', category: 'vegetables', calories: 87, protein: 1.9, carbs: 20, fat: 0.1, tags: ['potato', 'potatoes', 'boiled potato'] },
  { id: 'FDB_000166', display_name: 'Sweet potato, cooked', category: 'vegetables', calories: 90, protein: 2, carbs: 20.7, fat: 0.1, tags: ['sweet potato'] },
  { id: 'FDB_000167', display_name: 'French fries', category: 'vegetables', calories: 312, protein: 3.4, carbs: 38, fat: 17, tags: ['fries', 'french fries', 'chips'] },
  { id: 'FDB_000168', display_name: 'Mashed potato', category: 'vegetables', calories: 113, protein: 2.5, carbs: 18, fat: 4, tags: ['mashed potato', 'mashed potatoes'] },
  { id: 'FDB_000169', display_name: 'Baked potato', category: 'vegetables', calories: 93, protein: 2.5, carbs: 21, fat: 0.1, tags: ['baked potato', 'jacket potato'] },
  { id: 'FDB_000170', display_name: 'Green beans, cooked', category: 'vegetables', calories: 35, protein: 1.9, carbs: 8, fat: 0.3, tags: ['green beans', 'string beans', 'haricot vert'] },
  { id: 'FDB_000171', display_name: 'Peas, cooked', category: 'vegetables', calories: 84, protein: 5.4, carbs: 15, fat: 0.4, tags: ['peas', 'green peas'] },
  { id: 'FDB_000172', display_name: 'Cauliflower, cooked', category: 'vegetables', calories: 25, protein: 1.8, carbs: 5, fat: 0.3, tags: ['cauliflower'] },
  { id: 'FDB_000173', display_name: 'Zucchini, cooked', category: 'vegetables', calories: 21, protein: 1.4, carbs: 4, fat: 0.4, tags: ['zucchini', 'courgette', 'summer squash'] },
  { id: 'FDB_000174', display_name: 'Eggplant, cooked', category: 'vegetables', calories: 35, protein: 1.1, carbs: 6.6, fat: 0.2, tags: ['eggplant', 'aubergine'] },
  { id: 'FDB_000175', display_name: 'Asparagus, cooked', category: 'vegetables', calories: 22, protein: 2.4, carbs: 4.2, fat: 0.2, tags: ['asparagus'] },
  { id: 'FDB_000176', display_name: 'Avocado, raw', category: 'vegetables', calories: 160, protein: 2, carbs: 8.5, fat: 14.7, tags: ['avocado', 'avocado'] },
  { id: 'FDB_000177', display_name: 'Mixed salad greens', category: 'vegetables', calories: 17, protein: 1.5, carbs: 3.3, fat: 0.3, tags: ['salad', 'mixed greens', 'garden salad', 'salad mix'] },
  { id: 'FDB_000178', display_name: 'Coleslaw', category: 'vegetables', calories: 78, protein: 1.3, carbs: 7, fat: 5.5, tags: ['coleslaw', 'slaw'] },
  { id: 'FDB_000179', display_name: 'Pickles, dill', category: 'vegetables', calories: 12, protein: 0.5, carbs: 2.4, fat: 0.1, tags: ['pickles', 'dill pickles', 'cucumber pickles'] },
  { id: 'FDB_000180', display_name: 'Olives, green', category: 'vegetables', calories: 145, protein: 1, carbs: 3.8, fat: 15.3, tags: ['olives', 'green olives'] },
  { id: 'FDB_000181', display_name: 'Garlic, raw', category: 'vegetables', calories: 149, protein: 6.4, carbs: 33, fat: 0.5, tags: ['garlic'] },
  { id: 'FDB_000182', display_name: 'Ginger, raw', category: 'vegetables', calories: 80, protein: 1.8, carbs: 18, fat: 0.7, tags: ['ginger', 'fresh ginger'] },
  { id: 'FDB_000183', display_name: 'Beetroot, cooked', category: 'vegetables', calories: 44, protein: 1.7, carbs: 10, fat: 0.2, tags: ['beetroot', 'beets'] },
  { id: 'FDB_000184', display_name: 'Pumpkin, cooked', category: 'vegetables', calories: 20, protein: 0.7, carbs: 5, fat: 0.1, tags: ['pumpkin', 'squash'] },
  { id: 'FDB_000185', display_name: 'Artichoke, cooked', category: 'vegetables', calories: 53, protein: 2.9, carbs: 12, fat: 0.3, tags: ['artichoke'] },
  { id: 'FDB_000186', display_name: 'Radish, raw', category: 'vegetables', calories: 16, protein: 0.7, carbs: 3.4, fat: 0.1, tags: ['radish', 'radishes'] },
  { id: 'FDB_000187', display_name: 'Turnip, cooked', category: 'vegetables', calories: 22, protein: 0.7, carbs: 5, fat: 0.1, tags: ['turnip'] },
  { id: 'FDB_000188', display_name: 'Brussels sprouts, cooked', category: 'vegetables', calories: 43, protein: 3.4, carbs: 9, fat: 0.5, tags: ['brussels sprouts', 'brussel sprouts'] },
  { id: 'FDB_000189', display_name: 'Okra, cooked', category: 'vegetables', calories: 33, protein: 2, carbs: 7, fat: 0.3, tags: ['okra', 'lady finger'] },

  { id: 'FDB_000251', display_name: 'Apple, raw', category: 'fruits', calories: 52, protein: 0.3, carbs: 14, fat: 0.2, tags: ['apple', 'apples'] },
  { id: 'FDB_000252', display_name: 'Banana, raw', category: 'fruits', calories: 89, protein: 1.1, carbs: 23, fat: 0.3, tags: ['banana', 'bananas'] },
  { id: 'FDB_000253', display_name: 'Orange, raw', category: 'fruits', calories: 47, protein: 0.9, carbs: 12, fat: 0.1, tags: ['orange', 'oranges', 'citrus'] },
  { id: 'FDB_000254', display_name: 'Strawberries, raw', category: 'fruits', calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, tags: ['strawberries', 'strawberry', 'berries'] },
  { id: 'FDB_000255', display_name: 'Grapes, red, raw', category: 'fruits', calories: 69, protein: 0.7, carbs: 18, fat: 0.2, tags: ['grapes', 'grape'] },
  { id: 'FDB_000256', display_name: 'Blueberries, raw', category: 'fruits', calories: 57, protein: 0.7, carbs: 14, fat: 0.3, tags: ['blueberries', 'blueberry'] },
  { id: 'FDB_000257', display_name: 'Mango, raw', category: 'fruits', calories: 60, protein: 0.8, carbs: 15, fat: 0.4, tags: ['mango', 'mangoes'] },
  { id: 'FDB_000258', display_name: 'Pineapple, raw', category: 'fruits', calories: 50, protein: 0.5, carbs: 13, fat: 0.1, tags: ['pineapple'] },
  { id: 'FDB_000259', display_name: 'Watermelon, raw', category: 'fruits', calories: 30, protein: 0.6, carbs: 7.6, fat: 0.2, tags: ['watermelon'] },
  { id: 'FDB_000260', display_name: 'Kiwi, raw', category: 'fruits', calories: 61, protein: 1.1, carbs: 15, fat: 0.5, tags: ['kiwi', 'kiwifruit'] },
  { id: 'FDB_000261', display_name: 'Peach, raw', category: 'fruits', calories: 39, protein: 0.9, carbs: 9.5, fat: 0.3, tags: ['peach', 'peaches'] },
  { id: 'FDB_000262', display_name: 'Pear, raw', category: 'fruits', calories: 57, protein: 0.4, carbs: 15, fat: 0.1, tags: ['pear', 'pears'] },
  { id: 'FDB_000263', display_name: 'Plum, raw', category: 'fruits', calories: 46, protein: 0.7, carbs: 11, fat: 0.3, tags: ['plum', 'plums'] },
  { id: 'FDB_000264', display_name: 'Cherries, raw', category: 'fruits', calories: 50, protein: 1, carbs: 12, fat: 0.3, tags: ['cherries', 'cherry'] },
  { id: 'FDB_000265', display_name: 'Lemon, raw', category: 'fruits', calories: 29, protein: 1.1, carbs: 9.3, fat: 0.3, tags: ['lemon', 'lemons'] },
  { id: 'FDB_000266', display_name: 'Lime, raw', category: 'fruits', calories: 30, protein: 0.7, carbs: 11, fat: 0.2, tags: ['lime', 'limes'] },
  { id: 'FDB_000267', display_name: 'Raspberries, raw', category: 'fruits', calories: 52, protein: 1.2, carbs: 12, fat: 0.7, tags: ['raspberries', 'raspberry'] },
  { id: 'FDB_000268', display_name: 'Blackberries, raw', category: 'fruits', calories: 43, protein: 1.4, carbs: 10, fat: 0.5, tags: ['blackberries', 'blackberry'] },
  { id: 'FDB_000269', display_name: 'Cantaloupe, raw', category: 'fruits', calories: 34, protein: 0.8, carbs: 8.2, fat: 0.2, tags: ['cantaloupe', 'melon'] },
  { id: 'FDB_000270', display_name: 'Coconut meat, raw', category: 'fruits', calories: 354, protein: 3.3, carbs: 15, fat: 33.5, tags: ['coconut', 'coconut meat'] },
  { id: 'FDB_000271', display_name: 'Pomegranate, raw', category: 'fruits', calories: 83, protein: 1.7, carbs: 19, fat: 1.2, tags: ['pomegranate'] },
  { id: 'FDB_000272', display_name: 'Dried apricots', category: 'fruits', calories: 241, protein: 3.4, carbs: 63, fat: 0.5, tags: ['dried apricots', 'apricots dried'] },
  { id: 'FDB_000273', display_name: 'Raisins', category: 'fruits', calories: 299, protein: 3.1, carbs: 79, fat: 0.5, tags: ['raisins', 'dried grapes'] },
  { id: 'FDB_000274', display_name: 'Dates, medjool', category: 'fruits', calories: 282, protein: 2.5, carbs: 75, fat: 0.4, tags: ['dates', 'medjool', 'dried fruit'] },
  { id: 'FDB_000275', display_name: 'Cranberries, dried', category: 'fruits', calories: 308, protein: 0.1, carbs: 82, fat: 0.4, tags: ['cranberries', 'dried cranberries'] },
  { id: 'FDB_000276', display_name: 'Grapefruit, raw', category: 'fruits', calories: 42, protein: 0.8, carbs: 11, fat: 0.1, tags: ['grapefruit'] },
  { id: 'FDB_000277', display_name: 'Fig, raw', category: 'fruits', calories: 74, protein: 0.8, carbs: 19, fat: 0.3, tags: ['fig', 'figs'] },
  { id: 'FDB_000278', display_name: 'Apricot, raw', category: 'fruits', calories: 48, protein: 1.4, carbs: 11, fat: 0.4, tags: ['apricot', 'apricots'] },
  { id: 'FDB_000279', display_name: 'Nectarine, raw', category: 'fruits', calories: 44, protein: 1.1, carbs: 11, fat: 0.3, tags: ['nectarine', 'nectarines'] },

  { id: 'FDB_000301', display_name: 'White rice, cooked', category: 'grains', calories: 130, protein: 2.7, carbs: 28, fat: 0.3, tags: ['white rice', 'rice', 'steamed rice'] },
  { id: 'FDB_000302', display_name: 'Brown rice, cooked', category: 'grains', calories: 111, protein: 2.6, carbs: 23, fat: 0.9, tags: ['brown rice'] },
  { id: 'FDB_000303', display_name: 'White bread', category: 'grains', calories: 265, protein: 9, carbs: 49, fat: 3.2, tags: ['white bread', 'bread', 'toast'] },
  { id: 'FDB_000304', display_name: 'Whole wheat bread', category: 'grains', calories: 247, protein: 13, carbs: 41, fat: 3.4, tags: ['whole wheat bread', 'brown bread', 'whole grain bread'] },
  { id: 'FDB_000305', display_name: 'Pasta, cooked', category: 'grains', calories: 131, protein: 5, carbs: 25, fat: 1.1, tags: ['pasta', 'spaghetti', 'noodles', 'macaroni'] },
  { id: 'FDB_000306', display_name: 'Oats, cooked', category: 'grains', calories: 71, protein: 2.5, carbs: 12, fat: 1.5, tags: ['oats', 'oatmeal', 'porridge'] },
  { id: 'FDB_000307', display_name: 'Quinoa, cooked', category: 'grains', calories: 120, protein: 4.4, carbs: 21, fat: 1.9, tags: ['quinoa'] },
  { id: 'FDB_000308', display_name: 'Couscous, cooked', category: 'grains', calories: 112, protein: 3.8, carbs: 23, fat: 0.2, tags: ['couscous'] },
  { id: 'FDB_000309', display_name: 'Barley, cooked', category: 'grains', calories: 123, protein: 2.3, carbs: 28, fat: 0.4, tags: ['barley'] },
  { id: 'FDB_000310', display_name: 'Corn tortilla', category: 'grains', calories: 218, protein: 5.7, carbs: 45, fat: 2.5, tags: ['corn tortilla', 'tortilla'] },
  { id: 'FDB_000311', display_name: 'Flour tortilla', category: 'grains', calories: 300, protein: 8, carbs: 49, fat: 7, tags: ['flour tortilla', 'wrap', 'burrito wrap'] },
  { id: 'FDB_000312', display_name: 'Naan bread', category: 'grains', calories: 246, protein: 8.6, carbs: 44, fat: 4.4, tags: ['naan', 'naan bread'] },
  { id: 'FDB_000313', display_name: 'Pita bread', category: 'grains', calories: 275, protein: 9, carbs: 55, fat: 1.2, tags: ['pita', 'pita bread'] },
  { id: 'FDB_000314', display_name: 'Bagel, plain', category: 'grains', calories: 250, protein: 10, carbs: 48, fat: 1.5, tags: ['bagel'] },
  { id: 'FDB_000315', display_name: 'Croissant', category: 'grains', calories: 406, protein: 8.2, carbs: 45, fat: 21, tags: ['croissant'] },
  { id: 'FDB_000316', display_name: 'Pancake, plain', category: 'grains', calories: 227, protein: 6, carbs: 28, fat: 10, tags: ['pancake', 'pancakes'] },
  { id: 'FDB_000317', display_name: 'Waffle, plain', category: 'grains', calories: 291, protein: 8, carbs: 33, fat: 14, tags: ['waffle', 'waffles'] },
  { id: 'FDB_000318', display_name: 'Cereal, bran flakes', category: 'grains', calories: 333, protein: 13, carbs: 72, fat: 1.3, tags: ['cereal', 'bran flakes', 'breakfast cereal'] },
  { id: 'FDB_000319', display_name: 'Granola', category: 'grains', calories: 471, protein: 10, carbs: 64, fat: 20, tags: ['granola'] },
  { id: 'FDB_000320', display_name: 'White flour, all-purpose', category: 'grains', calories: 364, protein: 10, carbs: 76, fat: 1, tags: ['flour', 'white flour', 'all purpose flour'] },
  { id: 'FDB_000321', display_name: 'Breadcrumbs', category: 'grains', calories: 395, protein: 13, carbs: 72, fat: 5.3, tags: ['breadcrumbs', 'bread crumbs'] },
  { id: 'FDB_000322', display_name: 'Croutons', category: 'grains', calories: 407, protein: 8, carbs: 74, fat: 7, tags: ['croutons'] },
  { id: 'FDB_000323', display_name: 'Pretzel, hard', category: 'grains', calories: 380, protein: 10, carbs: 80, fat: 2.9, tags: ['pretzel', 'pretzels'] },
  { id: 'FDB_000324', display_name: 'Crackers, saltine', category: 'grains', calories: 418, protein: 10, carbs: 74, fat: 9, tags: ['crackers', 'saltines', 'soda crackers'] },

  { id: 'FDB_000351', display_name: 'Whole milk', category: 'dairy', calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, tags: ['whole milk', 'full cream milk', 'milk'] },
  { id: 'FDB_000352', display_name: '2% reduced fat milk', category: 'dairy', calories: 50, protein: 3.3, carbs: 4.8, fat: 2, tags: ['2% milk', 'reduced fat milk'] },
  { id: 'FDB_000353', display_name: 'Skim milk', category: 'dairy', calories: 34, protein: 3.4, carbs: 5, fat: 0.1, tags: ['skim milk', 'fat free milk', 'nonfat milk'] },
  { id: 'FDB_000354', display_name: 'Cheddar cheese', category: 'dairy', calories: 403, protein: 25, carbs: 1.3, fat: 33, tags: ['cheddar', 'cheddar cheese', 'cheese'] },
  { id: 'FDB_000355', display_name: 'Mozzarella cheese', category: 'dairy', calories: 280, protein: 28, carbs: 3.1, fat: 17, tags: ['mozzarella', 'mozzarella cheese'] },
  { id: 'FDB_000356', display_name: 'Parmesan cheese', category: 'dairy', calories: 431, protein: 38, carbs: 3.4, fat: 29, tags: ['parmesan', 'parmesan cheese'] },
  { id: 'FDB_000357', display_name: 'Greek yogurt, plain', category: 'dairy', calories: 97, protein: 9, carbs: 3.6, fat: 5, tags: ['greek yogurt', 'yogurt', 'plain yogurt'] },
  { id: 'FDB_000358', display_name: 'Yogurt, plain, low fat', category: 'dairy', calories: 63, protein: 5.3, carbs: 7, fat: 1.6, tags: ['low fat yogurt', 'yogurt low fat'] },
  { id: 'FDB_000359', display_name: 'Butter, salted', category: 'dairy', calories: 717, protein: 0.9, carbs: 0.1, fat: 81, tags: ['butter'] },
  { id: 'FDB_000360', display_name: 'Cream, heavy whipping', category: 'dairy', calories: 345, protein: 2.8, carbs: 2.8, fat: 37, tags: ['cream', 'heavy cream', 'whipping cream'] },
  { id: 'FDB_000361', display_name: 'Sour cream', category: 'dairy', calories: 198, protein: 2.4, carbs: 4.6, fat: 19, tags: ['sour cream'] },
  { id: 'FDB_000362', display_name: 'Cream cheese', category: 'dairy', calories: 342, protein: 6.2, carbs: 4.1, fat: 34, tags: ['cream cheese'] },
  { id: 'FDB_000363', display_name: 'Egg, whole, cooked', category: 'dairy', calories: 155, protein: 13, carbs: 1.1, fat: 11, tags: ['egg', 'eggs', 'scrambled egg', 'fried egg'] },
  { id: 'FDB_000364', display_name: 'Egg white, cooked', category: 'dairy', calories: 52, protein: 11, carbs: 0.7, fat: 0.2, tags: ['egg white', 'egg whites'] },
  { id: 'FDB_000365', display_name: 'Cottage cheese', category: 'dairy', calories: 98, protein: 11, carbs: 3.4, fat: 4.3, tags: ['cottage cheese'] },
  { id: 'FDB_000366', display_name: 'Ricotta cheese', category: 'dairy', calories: 174, protein: 11, carbs: 3, fat: 13, tags: ['ricotta', 'ricotta cheese'] },
  { id: 'FDB_000367', display_name: 'Feta cheese', category: 'dairy', calories: 264, protein: 14, carbs: 4, fat: 21, tags: ['feta', 'feta cheese'] },
  { id: 'FDB_000368', display_name: 'Goat cheese', category: 'dairy', calories: 300, protein: 21, carbs: 0.4, fat: 24, tags: ['goat cheese', 'chevre'] },
  { id: 'FDB_000369', display_name: 'Evaporated milk', category: 'dairy', calories: 134, protein: 6.8, carbs: 10, fat: 7.6, tags: ['evaporated milk'] },
  { id: 'FDB_000370', display_name: 'Condensed milk, sweetened', category: 'dairy', calories: 321, protein: 8, carbs: 54, fat: 8.7, tags: ['condensed milk', 'sweetened condensed milk'] },
  { id: 'FDB_000371', display_name: 'Ice cream, vanilla', category: 'dairy', calories: 207, protein: 3.5, carbs: 24, fat: 11, tags: ['ice cream', 'vanilla ice cream'] },

  { id: 'FDB_000401', display_name: 'Black beans, cooked', category: 'legumes_nuts', calories: 132, protein: 8.9, carbs: 24, fat: 0.5, tags: ['black beans', 'beans'] },
  { id: 'FDB_000402', display_name: 'Kidney beans, cooked', category: 'legumes_nuts', calories: 127, protein: 8.7, carbs: 23, fat: 0.5, tags: ['kidney beans', 'red beans'] },
  { id: 'FDB_000403', display_name: 'Lentils, cooked', category: 'legumes_nuts', calories: 116, protein: 9, carbs: 20, fat: 0.4, tags: ['lentils', 'lentil'] },
  { id: 'FDB_000404', display_name: 'Chickpeas, cooked', category: 'legumes_nuts', calories: 139, protein: 7.6, carbs: 22, fat: 2.6, tags: ['chickpeas', 'chickpea', 'garbanzo'] },
  { id: 'FDB_000405', display_name: 'Hummus', category: 'legumes_nuts', calories: 166, protein: 7.9, carbs: 14, fat: 9.6, tags: ['hummus'] },
  { id: 'FDB_000406', display_name: 'Tofu, firm', category: 'legumes_nuts', calories: 76, protein: 8, carbs: 1.9, fat: 4.8, tags: ['tofu', 'bean curd'] },
  { id: 'FDB_000407', display_name: 'Edamame, cooked', category: 'legumes_nuts', calories: 122, protein: 11, carbs: 9.9, fat: 5.2, tags: ['edamame', 'soybeans'] },
  { id: 'FDB_000408', display_name: 'Peanuts, roasted', category: 'legumes_nuts', calories: 599, protein: 25, carbs: 16, fat: 51, tags: ['peanuts', 'peanut'] },
  { id: 'FDB_000409', display_name: 'Almonds, raw', category: 'legumes_nuts', calories: 579, protein: 21, carbs: 22, fat: 50, tags: ['almonds', 'almond'] },
  { id: 'FDB_000410', display_name: 'Walnuts, raw', category: 'legumes_nuts', calories: 654, protein: 15, carbs: 14, fat: 65, tags: ['walnuts', 'walnut'] },
  { id: 'FDB_000411', display_name: 'Cashews, roasted', category: 'legumes_nuts', calories: 574, protein: 18, carbs: 30, fat: 44, tags: ['cashews', 'cashew'] },
  { id: 'FDB_000412', display_name: 'Pistachios, roasted', category: 'legumes_nuts', calories: 562, protein: 21, carbs: 28, fat: 45, tags: ['pistachios', 'pistachio'] },
  { id: 'FDB_000413', display_name: 'Sunflower seeds', category: 'legumes_nuts', calories: 584, protein: 21, carbs: 20, fat: 51, tags: ['sunflower seeds', 'sunflower seed'] },
  { id: 'FDB_000414', display_name: 'Pumpkin seeds', category: 'legumes_nuts', calories: 559, protein: 30, carbs: 11, fat: 49, tags: ['pumpkin seeds', 'pepitas'] },
  { id: 'FDB_000415', display_name: 'Peanut butter', category: 'legumes_nuts', calories: 588, protein: 25, carbs: 20, fat: 50, tags: ['peanut butter'] },
  { id: 'FDB_000416', display_name: 'Almond butter', category: 'legumes_nuts', calories: 614, protein: 21, carbs: 19, fat: 56, tags: ['almond butter'] },
  { id: 'FDB_000417', display_name: 'Chia seeds', category: 'legumes_nuts', calories: 486, protein: 17, carbs: 42, fat: 31, tags: ['chia seeds', 'chia'] },
  { id: 'FDB_000418', display_name: 'Flax seeds', category: 'legumes_nuts', calories: 534, protein: 18, carbs: 29, fat: 42, tags: ['flax seeds', 'flaxseed', 'linseed'] },

  { id: 'FDB_000421', display_name: 'Olive oil', category: 'fats_oils', calories: 884, protein: 0, carbs: 0, fat: 100, tags: ['olive oil'] },
  { id: 'FDB_000422', display_name: 'Coconut oil', category: 'fats_oils', calories: 862, protein: 0, carbs: 0, fat: 100, tags: ['coconut oil'] },
  { id: 'FDB_000423', display_name: 'Canola oil', category: 'fats_oils', calories: 884, protein: 0, carbs: 0, fat: 100, tags: ['canola oil', 'vegetable oil'] },
  { id: 'FDB_000424', display_name: 'Sesame oil', category: 'fats_oils', calories: 884, protein: 0, carbs: 0, fat: 100, tags: ['sesame oil'] },
  { id: 'FDB_000425', display_name: 'Sunflower oil', category: 'fats_oils', calories: 884, protein: 0, carbs: 0, fat: 100, tags: ['sunflower oil'] },
  { id: 'FDB_000426', display_name: 'Vegetable oil', category: 'fats_oils', calories: 884, protein: 0, carbs: 0, fat: 100, tags: ['vegetable oil', 'frying oil'] },
  { id: 'FDB_000427', display_name: 'Mayonnaise', category: 'fats_oils', calories: 700, protein: 1, carbs: 0.6, fat: 78, tags: ['mayonnaise', 'mayo'] },
  { id: 'FDB_000428', display_name: 'Balsamic vinaigrette', category: 'fats_oils', calories: 290, protein: 0.5, carbs: 14, fat: 26, tags: ['vinaigrette', 'balsamic dressing', 'salad dressing'] },
  { id: 'FDB_000429', display_name: 'Ranch dressing', category: 'fats_oils', calories: 430, protein: 1, carbs: 3, fat: 46, tags: ['ranch dressing', 'ranch'] },
  { id: 'FDB_000430', display_name: 'Italian dressing', category: 'fats_oils', calories: 290, protein: 0.3, carbs: 6, fat: 29, tags: ['italian dressing'] },
  { id: 'FDB_000431', display_name: 'Ghee', category: 'fats_oils', calories: 876, protein: 0, carbs: 0, fat: 99.5, tags: ['ghee', 'clarified butter'] },
  { id: 'FDB_000432', display_name: 'Lard', category: 'fats_oils', calories: 902, protein: 0, carbs: 0, fat: 100, tags: ['lard'] },

  { id: 'FDB_000441', display_name: 'Water', category: 'drinks', calories: 0, protein: 0, carbs: 0, fat: 0, tags: ['water'] },
  { id: 'FDB_000442', display_name: 'Coffee, black', category: 'drinks', calories: 2, protein: 0.3, carbs: 0, fat: 0, tags: ['coffee', 'black coffee', 'brewed coffee'] },
  { id: 'FDB_000443', display_name: 'Tea, black, brewed', category: 'drinks', calories: 1, protein: 0, carbs: 0, fat: 0, tags: ['tea', 'black tea'] },
  { id: 'FDB_000444', display_name: 'Orange juice', category: 'drinks', calories: 45, protein: 0.7, carbs: 10, fat: 0.2, tags: ['orange juice', 'oj'] },
  { id: 'FDB_000445', display_name: 'Apple juice', category: 'drinks', calories: 46, protein: 0.1, carbs: 11, fat: 0.1, tags: ['apple juice'] },
  { id: 'FDB_000446', display_name: 'Cola soda', category: 'drinks', calories: 41, protein: 0, carbs: 10, fat: 0, tags: ['cola', 'coke', 'soda', 'soft drink', 'coca cola'] },
  { id: 'FDB_000447', display_name: 'Diet cola soda', category: 'drinks', calories: 1, protein: 0, carbs: 0, fat: 0, tags: ['diet coke', 'diet cola', 'zero sugar soda'] },
  { id: 'FDB_000448', display_name: 'Milk shake', category: 'drinks', calories: 135, protein: 4, carbs: 22, fat: 3.6, tags: ['milkshake', 'milk shake', 'thick shake'] },
  { id: 'FDB_000449', display_name: 'Smoothie, fruit', category: 'drinks', calories: 58, protein: 1.3, carbs: 13, fat: 0.3, tags: ['smoothie', 'fruit smoothie'] },
  { id: 'FDB_000450', display_name: 'Beer', category: 'drinks', calories: 43, protein: 0.5, carbs: 3.6, fat: 0, tags: ['beer', 'lager', 'ale'] },
  { id: 'FDB_000451', display_name: 'Wine, red', category: 'drinks', calories: 85, protein: 0.1, carbs: 2.6, fat: 0, tags: ['red wine', 'wine'] },
  { id: 'FDB_000452', display_name: 'Wine, white', category: 'drinks', calories: 82, protein: 0.1, carbs: 2.6, fat: 0, tags: ['white wine'] },
  { id: 'FDB_000453', display_name: 'Coconut water', category: 'drinks', calories: 19, protein: 0.7, carbs: 3.7, fat: 0.2, tags: ['coconut water'] },
  { id: 'FDB_000454', display_name: 'Sports drink', category: 'drinks', calories: 24, protein: 0, carbs: 6, fat: 0, tags: ['sports drink', 'gatorade', 'powerade'] },

  { id: 'FDB_000461', display_name: 'Chocolate cake', category: 'desserts', calories: 371, protein: 5.3, carbs: 53, fat: 16, tags: ['chocolate cake', 'cake'] },
  { id: 'FDB_000462', display_name: 'Cheesecake', category: 'desserts', calories: 321, protein: 5.5, carbs: 26, fat: 22, tags: ['cheesecake'] },
  { id: 'FDB_000463', display_name: 'Chocolate chip cookie', category: 'desserts', calories: 488, protein: 5.7, carbs: 63, fat: 24, tags: ['cookie', 'chocolate chip cookie', 'cookies'] },
  { id: 'FDB_000464', display_name: 'Brownie', category: 'desserts', calories: 405, protein: 5, carbs: 51, fat: 21, tags: ['brownie', 'brownies'] },
  { id: 'FDB_000465', display_name: 'Doughnut, glazed', category: 'desserts', calories: 421, protein: 5.6, carbs: 48, fat: 24, tags: ['doughnut', 'donut', 'glazed donut'] },
  { id: 'FDB_000466', display_name: 'Milk chocolate bar', category: 'desserts', calories: 535, protein: 7.6, carbs: 59, fat: 30, tags: ['chocolate', 'milk chocolate', 'chocolate bar'] },
  { id: 'FDB_000467', display_name: 'Dark chocolate', category: 'desserts', calories: 546, protein: 4.9, carbs: 61, fat: 31, tags: ['dark chocolate'] },
  { id: 'FDB_000468', display_name: 'Pudding, chocolate', category: 'desserts', calories: 150, protein: 3.5, carbs: 25, fat: 4.5, tags: ['pudding', 'chocolate pudding'] },
  { id: 'FDB_000469', display_name: 'Pastry, croissant-like', category: 'desserts', calories: 406, protein: 8, carbs: 46, fat: 21, tags: ['pastry'] },
  { id: 'FDB_000470', display_name: 'Cinnamon roll', category: 'desserts', calories: 372, protein: 6, carbs: 55, fat: 15, tags: ['cinnamon roll', 'cinnamon bun'] },
  { id: 'FDB_000471', display_name: 'Fruit pie, apple', category: 'desserts', calories: 237, protein: 2, carbs: 34, fat: 11, tags: ['apple pie', 'pie'] },
  { id: 'FDB_000472', display_name: 'Muffin, blueberry', category: 'desserts', calories: 329, protein: 5, carbs: 51, fat: 13, tags: ['muffin', 'blueberry muffin'] },
  { id: 'FDB_000473', display_name: 'Jelly, jam', category: 'desserts', calories: 250, protein: 0.3, carbs: 65, fat: 0.1, tags: ['jam', 'jelly', 'marmalade'] },
  { id: 'FDB_000474', display_name: 'Honey', category: 'desserts', calories: 304, protein: 0.3, carbs: 82, fat: 0, tags: ['honey'] },
  { id: 'FDB_000475', display_name: 'Maple syrup', category: 'desserts', calories: 260, protein: 0, carbs: 67, fat: 0, tags: ['maple syrup'] },
  { id: 'FDB_000476', display_name: 'Vanilla ice cream', category: 'desserts', calories: 207, protein: 3.5, carbs: 24, fat: 11, tags: ['vanilla ice cream', 'ice cream'] },

  { id: 'FDB_000481', display_name: 'Pizza, cheese', category: 'fast_food', calories: 266, protein: 11, carbs: 33, fat: 10, tags: ['pizza', 'cheese pizza'] },
  { id: 'FDB_000482', display_name: 'Pizza, pepperoni', category: 'fast_food', calories: 298, protein: 13, carbs: 31, fat: 14, tags: ['pepperoni pizza'] },
  { id: 'FDB_000483', display_name: 'Hamburger, single patty', category: 'fast_food', calories: 250, protein: 13, carbs: 30, fat: 9, tags: ['hamburger', 'burger', 'cheeseburger'] },
  { id: 'FDB_000484', display_name: 'Cheeseburger', category: 'fast_food', calories: 300, protein: 15, carbs: 27, fat: 15, tags: ['cheeseburger', 'burger with cheese'] },
  { id: 'FDB_000485', display_name: 'French fries, medium', category: 'fast_food', calories: 312, protein: 3.4, carbs: 38, fat: 17, tags: ['fries', 'french fries', 'chips'] },
  { id: 'FDB_000486', display_name: 'Chicken nuggets', category: 'fast_food', calories: 296, protein: 14, carbs: 16, fat: 20, tags: ['chicken nuggets', 'nuggets'] },
  { id: 'FDB_000487', display_name: 'Fish and chips', category: 'fast_food', calories: 262, protein: 13, carbs: 27, fat: 12, tags: ['fish and chips'] },
  { id: 'FDB_000488', display_name: 'Submarine sandwich', category: 'fast_food', calories: 200, protein: 10, carbs: 24, fat: 7, tags: ['sub', 'sandwich', 'submarine'] },
  { id: 'FDB_000489', display_name: 'Taco, beef', category: 'fast_food', calories: 226, protein: 10, carbs: 20, fat: 12, tags: ['taco', 'beef taco'] },
  { id: 'FDB_000490', display_name: 'Burrito, beef', category: 'fast_food', calories: 224, protein: 10, carbs: 27, fat: 9, tags: ['burrito'] },
  { id: 'FDB_000491', display_name: 'Quesadilla', category: 'fast_food', calories: 294, protein: 12, carbs: 26, fat: 16, tags: ['quesadilla'] },
  { id: 'FDB_000492', display_name: 'Nachos', category: 'fast_food', calories: 306, protein: 7, carbs: 32, fat: 17, tags: ['nachos'] },
  { id: 'FDB_000493', display_name: 'Onion rings, fried', category: 'fast_food', calories: 318, protein: 4, carbs: 33, fat: 19, tags: ['onion rings'] },
  { id: 'FDB_000494', display_name: 'Chicken sandwich, fried', category: 'fast_food', calories: 270, protein: 14, carbs: 30, fat: 11, tags: ['chicken sandwich', 'chicken burger'] },
  { id: 'FDB_000495', display_name: 'Hot dog with bun', category: 'fast_food', calories: 290, protein: 11, carbs: 24, fat: 17, tags: ['hot dog'] },
  { id: 'FDB_000496', display_name: 'Mac and cheese', category: 'fast_food', calories: 164, protein: 6, carbs: 20, fat: 7, tags: ['mac and cheese', 'macaroni cheese'] },

  { id: 'FDB_000531', display_name: 'Chicken curry', category: 'international', calories: 170, protein: 18, carbs: 7, fat: 8, tags: ['chicken curry', 'curry'] },
  { id: 'FDB_000532', display_name: 'Chicken tikka masala', category: 'international', calories: 180, protein: 16, carbs: 8, fat: 10, tags: ['chicken tikka masala', 'tikka masala'] },
  { id: 'FDB_000533', display_name: 'Biryani, chicken', category: 'international', calories: 195, protein: 8, carbs: 28, fat: 6, tags: ['biryani', 'chicken biryani'] },
  { id: 'FDB_000534', display_name: 'Dal (lentil curry)', category: 'international', calories: 116, protein: 9, carbs: 20, fat: 0.4, tags: ['dal', 'dhal', 'lentil curry'] },
  { id: 'FDB_000535', display_name: 'Sushi, salmon roll', category: 'international', calories: 142, protein: 6, carbs: 26, fat: 2, tags: ['sushi', 'salmon roll', 'maki'] },
  { id: 'FDB_000536', display_name: 'Sushi, California roll', category: 'international', calories: 136, protein: 4.5, carbs: 27, fat: 1.5, tags: ['california roll', 'sushi roll'] },
  { id: 'FDB_000537', display_name: 'Ramen, tonkotsu', category: 'international', calories: 121, protein: 5, carbs: 14, fat: 5.5, tags: ['ramen', 'noodle soup', 'tonkotsu'] },
  { id: 'FDB_000538', display_name: 'Fried rice', category: 'international', calories: 168, protein: 5, carbs: 26, fat: 5, tags: ['fried rice', 'chinese fried rice'] },
  { id: 'FDB_000539', display_name: 'Chow mein', category: 'international', calories: 162, protein: 6, carbs: 24, fat: 5, tags: ['chow mein', 'lo mein', 'stir fry noodles'] },
  { id: 'FDB_000540', display_name: 'Spring rolls, fried', category: 'international', calories: 175, protein: 5, carbs: 22, fat: 8, tags: ['spring rolls', 'spring roll'] },
  { id: 'FDB_000541', display_name: 'Dumplings, steamed', category: 'international', calories: 111, protein: 6, carbs: 17, fat: 2.5, tags: ['dumplings', 'dim sum', 'gyoza'] },
  { id: 'FDB_000542', display_name: 'Sashimi, salmon', category: 'international', calories: 153, protein: 20, carbs: 0, fat: 7.5, tags: ['sashimi', 'raw fish'] },
  { id: 'FDB_000543', display_name: 'Pad thai', category: 'international', calories: 193, protein: 6, carbs: 31, fat: 6, tags: ['pad thai', 'thai noodles'] },
  { id: 'FDB_000544', display_name: 'Green curry', category: 'international', calories: 140, protein: 8, carbs: 6, fat: 10, tags: ['green curry', 'thai curry'] },
  { id: 'FDB_000545', display_name: 'Falafel', category: 'international', calories: 333, protein: 13, carbs: 32, fat: 18, tags: ['falafel'] },
  { id: 'FDB_000546', display_name: 'Shawarma, chicken', category: 'international', calories: 193, protein: 18, carbs: 22, fat: 5, tags: ['shawarma', 'chicken shawarma'] },
  { id: 'FDB_000547', display_name: 'Kebab, grilled', category: 'international', calories: 210, protein: 22, carbs: 3, fat: 12, tags: ['kebab', 'kabob', 'skewer'] },
  { id: 'FDB_000548', display_name: 'Hummus with pita', category: 'international', calories: 220, protein: 8, carbs: 30, fat: 9, tags: ['hummus and pita'] },
  { id: 'FDB_000549', display_name: 'Baba ganoush', category: 'international', calories: 78, protein: 1.5, carbs: 5, fat: 6.2, tags: ['baba ganoush', 'baba ghanoush'] },
  { id: 'FDB_000550', display_name: 'Paella', category: 'international', calories: 150, protein: 8, carbs: 22, fat: 3.5, tags: ['paella', 'spanish rice'] },
  { id: 'FDB_000551', display_name: 'Risotto', category: 'international', calories: 130, protein: 3.5, carbs: 22, fat: 3.5, tags: ['risotto'] },
  { id: 'FDB_000552', display_name: 'Pasta carbonara', category: 'international', calories: 215, protein: 9, carbs: 22, fat: 10, tags: ['carbonara', 'pasta carbonara'] },
  { id: 'FDB_000553', display_name: 'Pasta bolognese', category: 'international', calories: 135, protein: 8, carbs: 18, fat: 3.5, tags: ['bolognese', 'spaghetti bolognese'] },
  { id: 'FDB_000554', display_name: 'Lasagna', category: 'international', calories: 175, protein: 10, carbs: 17, fat: 8, tags: ['lasagna', 'lasagne'] },
  { id: 'FDB_000555', display_name: 'Margherita pizza', category: 'international', calories: 238, protein: 10, carbs: 30, fat: 9, tags: ['margherita pizza', 'margherita'] },
  { id: 'FDB_000556', display_name: 'Taco, chicken', category: 'international', calories: 210, protein: 12, carbs: 20, fat: 10, tags: ['chicken taco'] },
  { id: 'FDB_000557', display_name: 'Enchilada', category: 'international', calories: 200, protein: 12, carbs: 17, fat: 11, tags: ['enchilada'] },
  { id: 'FDB_000558', display_name: 'Tamale', category: 'international', calories: 280, protein: 7, carbs: 33, fat: 14, tags: ['tamale', 'tamales'] },
  { id: 'FDB_000559', display_name: 'Kimchi', category: 'international', calories: 24, protein: 1.1, carbs: 4, fat: 0.5, tags: ['kimchi'] },
  { id: 'FDB_000560', display_name: 'Bibimbap', category: 'international', calories: 175, protein: 7, carbs: 30, fat: 3.5, tags: ['bibimbap', 'korean rice bowl'] },
  { id: 'FDB_000561', display_name: 'Teriyaki chicken', category: 'international', calories: 175, protein: 16, carbs: 12, fat: 7, tags: ['teriyaki chicken', 'teriyaki'] },
  { id: 'FDB_000562', display_name: 'Tempura, shrimp', category: 'international', calories: 225, protein: 11, carbs: 18, fat: 13, tags: ['tempura', 'shrimp tempura'] },
  { id: 'FDB_000563', display_name: 'Miso soup', category: 'international', calories: 36, protein: 2.5, carbs: 4, fat: 1.1, tags: ['miso soup'] },
  { id: 'FDB_000564', display_name: 'Edamame, salted', category: 'international', calories: 121, protein: 12, carbs: 8.9, fat: 5.2, tags: ['edamame', 'salted edamame'] },
  { id: 'FDB_000565', display_name: 'Kung pao chicken', category: 'international', calories: 190, protein: 16, carbs: 10, fat: 11, tags: ['kung pao chicken'] },
  { id: 'FDB_000566', display_name: 'Sweet and sour chicken', category: 'international', calories: 210, protein: 12, carbs: 24, fat: 8, tags: ['sweet and sour chicken'] },
  { id: 'FDB_000567', display_name: 'Mongolian beef', category: 'international', calories: 220, protein: 18, carbs: 10, fat: 13, tags: ['mongolian beef'] },
  { id: 'FDB_000568', display_name: 'Beef broccoli', category: 'international', calories: 150, protein: 12, carbs: 10, fat: 7, tags: ['beef and broccoli'] },
  { id: 'FDB_000569', display_name: 'General Tso chicken', category: 'international', calories: 240, protein: 14, carbs: 22, fat: 12, tags: ['general tso chicken', 'general tso'] },
  { id: 'FDB_000570', display_name: 'Naan, garlic', category: 'international', calories: 262, protein: 8, carbs: 45, fat: 6, tags: ['garlic naan'] },
  { id: 'FDB_000571', display_name: 'Samosa, vegetable', category: 'international', calories: 260, protein: 5, carbs: 32, fat: 13, tags: ['samosa', 'samosas'] },
  { id: 'FDB_000572', display_name: 'Tandoori chicken', category: 'international', calories: 190, protein: 23, carbs: 3, fat: 10, tags: ['tandoori chicken'] },
  { id: 'FDB_000573', display_name: 'Butter chicken', category: 'international', calories: 200, protein: 18, carbs: 8, fat: 12, tags: ['butter chicken'] },
  { id: 'FDB_000574', display_name: 'Palak paneer', category: 'international', calories: 120, protein: 8, carbs: 6, fat: 8, tags: ['palak paneer'] },
  { id: 'FDB_000575', display_name: 'Chana masala', category: 'international', calories: 140, protein: 7, carbs: 20, fat: 4, tags: ['chana masala', 'chickpea curry'] },
  { id: 'FDB_000576', display_name: 'Lamb vindaloo', category: 'international', calories: 200, protein: 16, carbs: 6, fat: 13, tags: ['vindaloo', 'lamb vindaloo'] },
  { id: 'FDB_000577', display_name: 'Kabsa, chicken', category: 'international', calories: 200, protein: 12, carbs: 25, fat: 6, tags: ['kabsa', 'chicken kabsa', 'machboos'] },
  { id: 'FDB_000578', display_name: 'Mandi, chicken', category: 'international', calories: 210, protein: 14, carbs: 22, fat: 7, tags: ['mandi', 'chicken mandi'] },
  { id: 'FDB_000579', display_name: 'Koshari', category: 'international', calories: 160, protein: 6, carbs: 28, fat: 3, tags: ['koshari'] },
  { id: 'FDB_000580', display_name: 'Dolma, stuffed grape leaves', category: 'international', calories: 130, protein: 4, carbs: 18, fat: 5, tags: ['dolma', 'grape leaves', 'stuffed vine leaves'] },
  { id: 'FDB_000581', display_name: 'Tabbouleh', category: 'international', calories: 75, protein: 2, carbs: 12, fat: 3, tags: ['tabbouleh', 'tabouli'] },
  { id: 'FDB_000582', display_name: 'Fattoush salad', category: 'international', calories: 85, protein: 2, carbs: 10, fat: 5, tags: ['fattoush', 'fattoush salad'] },
  { id: 'FDB_000583', display_name: 'Poke bowl, salmon', category: 'international', calories: 150, protein: 12, carbs: 18, fat: 4, tags: ['poke bowl', 'poke'] },
  { id: 'FDB_000584', display_name: 'Acai bowl', category: 'international', calories: 120, protein: 2, carbs: 22, fat: 3, tags: ['acai bowl', 'acai'] },
];

async function buildDatabase() {
  const db = {};
  const aliasMap = {};
  let foodIndex = 0;

  if (USDA_API_KEY) {
    console.log('USDA API key found. Fetching data from USDA FoodData Central...');
    await fetchFromUSDA(db, aliasMap);
    console.log(`Fetched ${Object.keys(db).length} foods from USDA.`);
  }

  for (const food of BASE_FOODS) {
    if (!db[food.id]) {
      db[food.id] = {
        display_name: food.display_name,
        calories: food.calories,
        protein: food.protein,
        carbs: food.carbs,
        fat: food.fat,
        category: food.category,
      };
    }
    for (const tag of food.tags) {
      const normalized = tag.toLowerCase().trim();
      if (!aliasMap[normalized]) {
        aliasMap[normalized] = food.id;
      }
    }
    aliasMap[food.display_name.toLowerCase()] = food.id;
  }

  const outputDir = path.join(__dirname, '..', 'data');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  fs.writeFileSync(
    path.join(outputDir, 'nutrition_db.json'),
    JSON.stringify(db, null, 2),
    'utf8'
  );
  console.log(`Wrote ${Object.keys(db).length} foods to nutrition_db.json`);

  fs.writeFileSync(
    path.join(outputDir, 'food_aliases.json'),
    JSON.stringify(aliasMap, null, 2),
    'utf8'
  );
  console.log(`Wrote ${Object.keys(aliasMap).length} aliases to food_aliases.json`);
}

async function fetchFromUSDA(db, aliasMap) {
  const categories = [
    'Meats', 'Poultry', 'Fish', 'Vegetables', 'Fruits',
    'Grains', 'Dairy', 'Legumes', 'Fats', 'Beverages',
    'Sweets', 'Fast Foods', 'Restaurant foods',
  ];

  for (const category of categories) {
    try {
      const response = await fetch(
        `${USDA_SEARCH_URL}?api_key=${USDA_API_KEY}&query=${encodeURIComponent(category)}&pageSize=50&dataType=SR%20Legacy`
      );
      const data = await response.json();
      if (data.foods) {
        for (const food of data.foods) {
          const id = `FDB_${String(food.fdcId).padStart(6, '0')}`;
          const nutrients = {};
          for (const n of food.foodNutrients || []) {
            if (n.nutrientName?.toLowerCase().includes('energy')) nutrients.calories = n.value || 0;
            if (n.nutrientName?.toLowerCase().includes('protein')) nutrients.protein = n.value || 0;
            if (n.nutrientName?.toLowerCase().includes('carbohydrate')) nutrients.carbs = n.value || 0;
            if (n.nutrientName?.toLowerCase().includes('total fat')) nutrients.fat = n.value || 0;
          }
          db[id] = {
            display_name: food.description || 'Unknown',
            calories: Math.round(nutrients.calories || 0),
            protein: Math.round((nutrients.protein || 0) * 10) / 10,
            carbs: Math.round((nutrients.carbs || 0) * 10) / 10,
            fat: Math.round((nutrients.fat || 0) * 10) / 10,
            category: category.toLowerCase().replace(/\s+/g, '_'),
          };
          aliasMap[food.description?.toLowerCase() || ''] = id;
        }
      }
    } catch (err) {
      console.error(`Failed to fetch USDA category "${category}":`, err.message);
    }
  }
}

buildDatabase().catch(console.error);
