select
  e.id AS episode_id,
  e.number,
  e.title,
  e.published_on,
  To_Char(published_on, 'day') as day,
  date_part('week', published_on::date)::INTEGER  as week,
  date_part('year', published_on::date)::INTEGER  as year,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '12 hours' AND ev.created_at >= CURRENT_DATE - INTERVAL '12 hours') THEN 1 END) AS a12h,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '1 day' AND ev.created_at >= CURRENT_DATE - INTERVAL '1 day') THEN 1 END) AS a1d,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '3 day' AND ev.created_at >= CURRENT_DATE - INTERVAL '3 day') THEN 1 END) AS a3d,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '7 day' AND ev.created_at >= CURRENT_DATE - INTERVAL '7 day') THEN 1 END) AS a7d,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '14 day' AND ev.created_at >= CURRENT_DATE - INTERVAL '14 day') THEN 1 END) AS a14d,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '30 day' AND ev.created_at >= CURRENT_DATE - INTERVAL '30 day') THEN 1 END) AS a30d,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '60 day' AND ev.created_at >= CURRENT_DATE - INTERVAL '60 day') THEN 1 END) AS a60d,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '3 month' AND ev.created_at >= CURRENT_DATE - INTERVAL '3 month') THEN 1 END) AS a3m,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '6 month' AND ev.created_at >= CURRENT_DATE - INTERVAL '6 month') THEN 1 END) AS a6m,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '12 month' AND ev.created_at >= CURRENT_DATE - INTERVAL '12 month') THEN 1 END) AS a12m,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '18 month' AND ev.created_at >= CURRENT_DATE - INTERVAL '18 month') THEN 1 END) AS a18m,
  COUNT(CASE WHEN (e.published_on <= CURRENT_DATE - INTERVAL '24 month' AND ev.created_at >= CURRENT_DATE - INTERVAL '24 month') THEN 1 END) AS a24m,
  COUNT(*) as cnt
FROM
  episodes e
  LEFT JOIN events ev ON e.id = ev.episode_id
where e.published_on  >= (select created_at from events order by created_at limit(1))
GROUP BY
  e.id
 order by a1d desc
