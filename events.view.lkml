view: events {
  sql_table_name: public.events ;;

  parameter: select_a_timeframe {
    type: string
    default_value: "created_week"
    allowed_value: {
      label: "Created Date"
      value: "date"
    }
    allowed_value: {
      label: "Created Week"
      value: "week"
    }
    allowed_value: {
      label: "Created Month"
      value: "month"
    }
    allowed_value: {
      label: "Created Year"
      value: "year"
    }
  }

  parameter: select_a_dimension {
    type: unquoted
    default_value: "os"
    allowed_value: {
      label: "Operating System"
      value: "os"
    }
    allowed_value: {
      label: "Browser"
      value: "browser"
    }
    allowed_value: {
      label: "Event Type"
      value: "event_type"
    }
  }

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: user_identifier {
    type: string
    sql: COALESCE(${user_id}::varchar, ${ip_address}) ;;
  }

  dimension: browser {
    type: string
    sql: ${TABLE}.browser ;;
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
  }

  dimension: country {
    type: string
    map_layer_name: countries
    sql: ${TABLE}.country ;;
  }

  dimension_group: created {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.created_at ;;
  }

  dimension: dynamic_timeframe {
    type: string
    label_from_parameter: select_a_timeframe
    sql: CASE
          WHEN {% parameter select_a_timeframe %} = 'date' THEN TO_CHAR(${created_date}, 'YYYY-MM-DD')
          WHEN {% parameter select_a_timeframe %} = 'week' THEN ${created_week}
          WHEN {% parameter select_a_timeframe %} = 'month' THEN ${created_month}
          ELSE TO_CHAR(${created_year}, '9999')
        END
          ;;
  }

  dimension: dynamic_dimension {
    type: string
    sql: ${TABLE}.{% parameter select_a_dimension %} ;;
  }

  dimension: event_type {
    type: string
    sql: ${TABLE}.event_type ;;
  }

  dimension: ip_address {
    type: string
    sql: ${TABLE}.ip_address ;;
  }

  dimension: latitude {
    type: number
    sql: ${TABLE}.latitude ;;
  }

  dimension: longitude {
    type: number
    sql: ${TABLE}.longitude ;;
  }

  dimension: location {
    type: location
    sql_latitude: ${latitude} ;;
    sql_longitude: ${longitude} ;;
  }

  dimension: os {
    type: string
    sql: ${TABLE}.os ;;
  }

  dimension: sequence_number {
    type: number
    sql: ${TABLE}.sequence_number ;;
  }

  dimension: session_id {
    type: string
    sql: ${TABLE}.session_id ;;
  }

  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
  }

  dimension: traffic_source {
    type: string
    sql: ${TABLE}.traffic_source ;;
  }

  dimension: uri {
    type: string
    sql: ${TABLE}.uri ;;
  }

  dimension: user_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  dimension: zip {
    type: zipcode
    sql: ${TABLE}.zip ;;
  }

  measure: count {
    type: count
    drill_fields: [id, users.id, users.first_name, users.last_name]
  }

  measure: count_distinct_user_identifiers {
    type: count_distinct
    sql: ${user_identifier} ;;
  }
}
