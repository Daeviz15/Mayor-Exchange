-- Create a powerful RPC function to calculate admin stats server-side
-- This replaces the inefficient client-side aggregation

CREATE OR REPLACE FUNCTION public.get_admin_leaderboard_v2()
RETURNS TABLE (
  admin_id uuid,
  display_name text,
  email character varying(255),
  total_processed bigint,
  total_completed bigint,
  total_rejected bigint,
  total_pending bigint,
  completion_rate numeric,
  today_count bigint,
  week_count bigint,
  month_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH admin_stats AS (
    SELECT
      t.admin_id,
      COUNT(*) AS total_processed,
      COUNT(*) FILTER (WHERE t.status = 'completed') AS total_completed,
      COUNT(*) FILTER (WHERE t.status = 'rejected') AS total_rejected,
      COUNT(*) FILTER (WHERE t.status IN ('pending', 'claimed', 'payment_pending')) AS total_pending,
      COUNT(*) FILTER (WHERE t.updated_at >= date_trunc('day', now())) AS today_count,
      COUNT(*) FILTER (WHERE t.updated_at >= date_trunc('week', now())) AS week_count,
      COUNT(*) FILTER (WHERE t.updated_at >= date_trunc('month', now())) AS month_count
    FROM
      transactions t
    WHERE
      t.admin_id IS NOT NULL
    GROUP BY
      t.admin_id
  )
  SELECT
    stats.admin_id,
    COALESCE(
        (m.raw_user_meta_data->>'display_name'),
        (m.raw_user_meta_data->>'full_name'),
        (m.raw_user_meta_data->>'name'),
        (m.raw_user_meta_data->>'firstName') || ' ' || (m.raw_user_meta_data->>'lastName'),
        split_part(au.email, '@', 1)
    ) AS display_name,
    au.email,
    stats.total_processed,
    stats.total_completed,
    stats.total_rejected,
    stats.total_pending,
    CASE 
      WHEN stats.total_processed > 0 
      THEN (stats.total_completed::numeric / stats.total_processed::numeric) * 100 
      ELSE 0 
    END AS completion_rate,
    stats.today_count,
    stats.week_count,
    stats.month_count
  FROM
    admin_stats stats
  JOIN
    auth.users au ON stats.admin_id = au.id
  LEFT JOIN
    auth.users m ON stats.admin_id = m.id; -- Join again to get metadata (redundant strictly speaking but cleaner for accessing JSONB)

END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_admin_leaderboard_v2() TO authenticated;
