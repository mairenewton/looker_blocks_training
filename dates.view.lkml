view: dates {
  derived_table: {
    distribution_style: all
    sortkeys: ["date"]
    sql_trigger_value:  GETDATE() ;;
    sql: -- Create a Date table with a row for each date.
      SELECT '2001-01-01'::DATE + d AS date
      FROM
        (SELECT ROW_NUMBER() OVER(ORDER BY id) -1 AS d FROM order_items ORDER BY id LIMIT 20000) AS  d
       ;;
  }
}
