view: active_users {
  derived_table: {
    sql_trigger_value: GETDATE();;
    distribution: "user_id"
    sortkeys: ["date"]
    sql:
      WITH daily_use AS (
        -- Create a table of days and activity by user_id
        SELECT
           COALESCE(user_id::varchar, ip_address) as user_identifier
          ,user_id
          ,DATE_TRUNC('day', created_at) as activity_date
          ,COUNT(*) as number_of_events
          ,COUNT(DISTINCT FLOOR(UNIX_TIMESTAMP(events.created_at)/(60*5))*5) as approximate_usage_in_minutes
        FROM events
        GROUP BY 1, 2, 3
      )
      -- Cross join activity and dates to build a row for each user/date combo with days since last activity
      SELECT
            daily_use.user_identifier
          , wd.date as date
          , MIN(wd.date::date - daily_use.activity_date::date) as days_since_last_action
          , SUM(number_of_events) as number_of_events
          , SUM(approximate_usage_in_minutes) as approximate_usage_in_minutes
      FROM ${dates.SQL_TABLE_NAME} as wd
      LEFT JOIN daily_use
          ON wd.date >= daily_use.activity_date
          AND wd.date < daily_use.activity_date + interval '30 day'
      GROUP BY 1,2
       ;;
  }

  dimension: primary_key {
    type: string
    primary_key: yes
    hidden: yes
    sql: ${date} || ' - ' || ${user_identifier} ;;
  }

  dimension: date {
    type: date
    sql: ${TABLE}.date ;;
  }

  dimension: user_identifier {
    type: number
    sql: ${TABLE}.user_identifier ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: days_since_last_action {
    type: number
    sql: ${TABLE}.days_since_last_action ;;
    value_format_name: decimal_0
  }

  dimension: active_this_day {
    type: yesno
    sql: ${days_since_last_action} <  1 ;;
  }

  dimension: active_last_7_days {
    type: yesno
    sql: ${days_since_last_action} < 7 ;;
  }

  measure: number_of_events {
    type: sum
    sql: ${TABLE}.number_of_events ;;
  }

  measure: approximate_usage_in_minutes {
    type: sum
    sql: ${TABLE}.approximate_usage_in_minutes ;;
  }

  measure: user_count_active_30_days {
    label: "Monthly Active Users"
    type: count_distinct
    sql: ${user_identifier} ;;
    drill_fields: [users.id, users.name]
  }

  measure: user_count_active_this_day {
    label: "Daily Active Users"
    type: count_distinct
    sql: ${user_identifier} ;;
    drill_fields: [users.id, users.name]

    filters: {
      field: active_this_day
      value: "yes"
    }
  }

  measure: user_count_active_7_days {
    label: "Weekly Active Users"
    type: count_distinct
    sql: ${user_identifier} ;;
    drill_fields: [users.id, users.name]

    filters: {
      field: active_last_7_days
      value: "yes"
    }
  }
}
