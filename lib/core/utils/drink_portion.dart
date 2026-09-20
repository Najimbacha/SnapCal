/// Only recognises common thin beverages. Dense foods (smoothies, shakes,
/// yoghurt, sauces) stay in grams without a measured density. For these drinks
/// the UI uses an explicit approximation of 1 g ≈ 1 ml; nutrition stays per 100 g.
bool usesApproximateDrinkVolume(String name) {
  final normalized =
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  return RegExp(
    r'^(?:(?:diet|zero|sugar free|zero sugar|no sugar|regular|sparkling|still|carbonated|unsweetened|sweetened|iced|hot|cold|fresh|freshly squeezed|canned|decaf|black|green|herbal) )*'
    r'(?:water|mineral water|coconut water|cola|pepsi|coca cola|coke|sprite|fanta|7 up|7up|soda|soft drink|energy drink|sports drink|lemonade|tea|coffee|'
    r'(?:(?:lemon|lime|mint|orange|apple|grape|grapefruit|pineapple|mango|fruit|cranberry|pomegranate|tomato) )+(?:juice|soda|drink|water|tea))'
    r'(?: (?:zero|diet|light|zero sugar|sugar free|no sugar))?$',
  ).hasMatch(normalized);
}
