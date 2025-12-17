-- Enable insert for authenticated users so Admins can create notifications for other users
create policy "Enable insert for authenticated users" on "public"."notifications"
    for insert to authenticated
    with check (true);
