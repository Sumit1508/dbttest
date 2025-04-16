-- macros/tests/custom_pkg_price_check.sql
{% test custom_pkg_price_check(model) %}
  WITH invalid_prices AS (
      SELECT *
      FROM {{ model }}
      WHERE pkg_price < 0
  )
  SELECT *
  FROM invalid_prices
  LIMIT 1
{% endtest %}
