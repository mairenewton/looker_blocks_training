view: user_retention {
  derived_table: {
    sql: SELECT
             users.id as user_id
            ,date(DATE_TRUNC('month', users.created_at)) as signup_month
            ,month_list.purchase_month as purchase_month
            ,COALESCE(data.monthly_purchases, 0) as monthly_purchases
            ,COALESCE(data.total_purchase_amount, 0) as monthly_spend
          FROM
            users

          LEFT JOIN

            (
              SELECT
                DISTINCT(date(DATE_TRUNC('month', order_items.created_at))) as purchase_month
              FROM order_items
            ) as month_list
          ON month_list.purchase_month >= date(DATE_TRUNC('month', users.created_at))

          LEFT JOIN

            (
              SELECT
                    oi.user_id
                  , date(DATE_TRUNC('month', oi.created_at)) as purchase_month
                  , COUNT(distinct oi.order_id) AS monthly_purchases
                  , sum(oi.sale_price) AS total_purchase_amount

              FROM order_items oi
              GROUP BY 1,2
            ) as data
          ON data.purchase_month = month_list.purchase_month
          AND data.user_id = users.id
           ;;


      persist_for: "24 hours"
      sortkeys: ["user_id"]
      distribution: "user_id"
    }

    dimension: user_id {
      type: number
      sql: ${TABLE}.user_id ;;
    }

    dimension_group: signup {
      type: time
      timeframes: [date, month, year]
      hidden: yes
      sql: ${TABLE}.signup_month;;
    }

    dimension_group: purchase {
      type: time
      timeframes: [date, month, year]
      hidden: yes
      sql: ${TABLE}.purchase_month ;;
    }

    dimension: months_since_signup {
      type: number
      sql:  datediff(month, ${signup_date}, ${purchase_date});;
    }

    dimension: monthly_purchases {
      type: number
      sql: ${TABLE}.monthly_purchases ;;
    }

    dimension: monthly_spend {
      type: number
      sql: ${TABLE}.monthly_spend ;;
    }

    measure: total_users {
      type: count_distinct
      sql: ${user_id} ;;
      drill_fields: [users.id, users.age, users.name, user_order_facts.lifetime_orders]
    }

    measure: total_active_users {
      type: count_distinct
      sql: ${user_id} ;;
      drill_fields: [users.id, users.age, users.name, user_order_facts.lifetime_orders]

      filters: {
        field: monthly_purchases
        value: ">0"
      }
    }

    measure: percent_of_cohort_active {
      type: number
      value_format_name: percent_1
      sql: 1.0 * ${total_active_users} / nullif(${total_users},0) ;;
      drill_fields: [user_id, monthly_purchases, total_amount_spent]
    }

    measure: total_amount_spent {
      type: sum
      value_format_name: usd
      sql: ${monthly_spend} ;;
      drill_fields: [detail*]
    }

    measure: spend_per_user {
      type: number
      value_format_name: usd
      sql: ${total_amount_spent} / nullif(${total_users},0) ;;
      drill_fields: [user_id, monthly_purchases, total_amount_spent]
    }

    dimension: primary_key {
      type: number
      primary_key: yes
      hidden: yes
      sql: concat(${purchase_month}, " - ", ${user_id}) ;;
    }

    set: detail {
      fields: [user_id, signup_month, monthly_purchases, monthly_spend]
    }

  }
