-- ============================================================================
-- 0004 — Seed writers and articles (10 per category, originally generated copy)
-- Run this AFTER 0003_feedback.sql.
-- ============================================================================

-- ---- Seed writer accounts ----
-- Inserting directly into auth.users is a common Supabase seeding pattern —
-- it works because the SQL editor runs with elevated privileges. Each insert
-- fires the handle_new_user() trigger, which creates the matching profiles row.
do $$
declare
  writer0_id uuid := gen_random_uuid();
  writer1_id uuid := gen_random_uuid();
  writer2_id uuid := gen_random_uuid();
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, confirmation_token, recovery_token
  ) values (
    '00000000-0000-0000-0000-000000000000', writer0_id, 'authenticated', 'authenticated',
    'ada.chukwu@seed.thegist.demo', crypt('SeedWriter!2026', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{"name":"Ada Chukwu"}', '', ''
  );
  update public.profiles set role = 'writer' where id = writer0_id;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, confirmation_token, recovery_token
  ) values (
    '00000000-0000-0000-0000-000000000000', writer1_id, 'authenticated', 'authenticated',
    'tari.amadi@seed.thegist.demo', crypt('SeedWriter!2026', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{"name":"Tari Amadi"}', '', ''
  );
  update public.profiles set role = 'writer' where id = writer1_id;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, confirmation_token, recovery_token
  ) values (
    '00000000-0000-0000-0000-000000000000', writer2_id, 'authenticated', 'authenticated',
    'chuka.eze@seed.thegist.demo', crypt('SeedWriter!2026', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{"name":"Chuka Eze"}', '', ''
  );
  update public.profiles set role = 'writer' where id = writer2_id;

end $$;

-- ---- Seed articles ----
do $$
declare
  a_id uuid;
  cat_id uuid;
  auth_id uuid;
  writer_emails text[] := array['ada.chukwu@seed.thegist.demo','tari.amadi@seed.thegist.demo','chuka.eze@seed.thegist.demo'];
begin
  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Inside the market union''s quiet fight over bus park control',
    'inside-the-market-union-s-quiet-fight-over-bus-park-control-01',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    1032,
    now() - interval '41 days',
    now() - interval '41 days',
    now() - interval '41 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why the new fuel subsidy rollback is splitting local traders',
    'why-the-new-fuel-subsidy-rollback-is-splitting-local-traders-02',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4587,
    now() - interval '7 days',
    now() - interval '7 days',
    now() - interval '7 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'State assembly quietly shelves the transport reform bill',
    'state-assembly-quietly-shelves-the-transport-reform-bill-03',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    1911,
    now() - interval '6 days',
    now() - interval '6 days',
    now() - interval '6 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Ward-level voter registration numbers are down — here''s why',
    'ward-level-voter-registration-numbers-are-down---here-s-why-04',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    4584,
    now() - interval '13 days',
    now() - interval '13 days',
    now() - interval '13 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The community town-hall that turned into a shouting match',
    'the-community-town-hall-that-turned-into-a-shouting-match-05',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>What''s changed this time, several sources agreed, is that people are finally documenting it as it happens. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    1427,
    now() - interval '1 days',
    now() - interval '1 days',
    now() - interval '1 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Local government elections: who''s actually on the ballot',
    'local-government-elections--who-s-actually-on-the-ballot-06',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. It began with a single post that a handful of neighbors shared before anyone official weighed in. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    957,
    now() - interval '22 days',
    now() - interval '22 days',
    now() - interval '22 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'A council seat, three candidates, and one contested register',
    'a-council-seat--three-candidates--and-one-contested-register-07',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. It began with a single post that a handful of neighbors shared before anyone official weighed in. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    2286,
    now() - interval '39 days',
    now() - interval '39 days',
    now() - interval '39 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why the new market levy is dividing shop owners',
    'why-the-new-market-levy-is-dividing-shop-owners-08',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>What''s changed this time, several sources agreed, is that people are finally documenting it as it happens. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    4642,
    now() - interval '6 days',
    now() - interval '6 days',
    now() - interval '6 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The road contract nobody can find the paperwork for',
    'the-road-contract-nobody-can-find-the-paperwork-for-09',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    495,
    now() - interval '5 days',
    now() - interval '5 days',
    now() - interval '5 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'What the new zoning rules mean for street vendors',
    'what-the-new-zoning-rules-mean-for-street-vendors-10',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    2397,
    now() - interval '25 days',
    now() - interval '25 days',
    now() - interval '25 days'
  );
  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The Afrobeats producers building studios in shipping containers',
    'the-afrobeats-producers-building-studios-in-shipping-contain-11',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    2307,
    now() - interval '14 days',
    now() - interval '14 days',
    now() - interval '14 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why local theatre is having a quiet resurgence downtown',
    'why-local-theatre-is-having-a-quiet-resurgence-downtown-12',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    3906,
    now() - interval '11 days',
    now() - interval '11 days',
    now() - interval '11 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Inside the community mural project reclaiming an underpass',
    'inside-the-community-mural-project-reclaiming-an-underpass-13',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    1996,
    now() - interval '4 days',
    now() - interval '4 days',
    now() - interval '4 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The vinyl shop that outlasted three shopping malls',
    'the-vinyl-shop-that-outlasted-three-shopping-malls-14',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    4766,
    now() - interval '14 days',
    now() - interval '14 days',
    now() - interval '14 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'A weekend guide to the neighborhood''s smallest galleries',
    'a-weekend-guide-to-the-neighborhood-s-smallest-galleries-15',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. Nobody involved expected this to still be unresolved months later, but here we are. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    2289,
    now() - interval '10 days',
    now() - interval '10 days',
    now() - interval '10 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'How a church choir became a Sunday-night open mic',
    'how-a-church-choir-became-a-sunday-night-open-mic-16',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>As always, we want to hear from anyone closer to this than we are. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    3629,
    now() - interval '38 days',
    now() - interval '38 days',
    now() - interval '38 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The tailor stitching three generations of wedding gowns',
    'the-tailor-stitching-three-generations-of-wedding-gowns-17',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    864,
    now() - interval '32 days',
    now() - interval '32 days',
    now() - interval '32 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Street food vendors are the city''s real food critics',
    'street-food-vendors-are-the-city-s-real-food-critics-18',
    '<p>It began with a single post that a handful of neighbors shared before anyone official weighed in. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>As always, we want to hear from anyone closer to this than we are. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    640,
    now() - interval '39 days',
    now() - interval '39 days',
    now() - interval '39 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The book club that only reads what its members write',
    'the-book-club-that-only-reads-what-its-members-write-19',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4652,
    now() - interval '17 days',
    now() - interval '17 days',
    now() - interval '17 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why everyone under 25 is suddenly learning highlife guitar',
    'why-everyone-under-25-is-suddenly-learning-highlife-guitar-20',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    2524,
    now() - interval '8 days',
    now() - interval '8 days',
    now() - interval '8 days'
  );
  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Naira stabilizes, but street traders say prices haven''t followed',
    'naira-stabilizes--but-street-traders-say-prices-haven-t-foll-21',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    1583,
    now() - interval '33 days',
    now() - interval '33 days',
    now() - interval '33 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The thrift market outgrowing its own square footage',
    'the-thrift-market-outgrowing-its-own-square-footage-22',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    3183,
    now() - interval '10 days',
    now() - interval '10 days',
    now() - interval '10 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Small importers are quietly rerouting around the port backlog',
    'small-importers-are-quietly-rerouting-around-the-port-backlo-23',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. What''s changed this time, several sources agreed, is that people are finally documenting it as it happens. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4122,
    now() - interval '21 days',
    now() - interval '21 days',
    now() - interval '21 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'A co-op of seamstresses just landed their first export order',
    'a-co-op-of-seamstresses-just-landed-their-first-export-order-24',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    2093,
    now() - interval '4 days',
    now() - interval '4 days',
    now() - interval '4 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why three fintech apps launched in this city in one month',
    'why-three-fintech-apps-launched-in-this-city-in-one-month-25',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>As always, we want to hear from anyone closer to this than we are. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    1171,
    now() - interval '9 days',
    now() - interval '9 days',
    now() - interval '9 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The generator-rental business booming on unreliable power',
    'the-generator-rental-business-booming-on-unreliable-power-26',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    3586,
    now() - interval '39 days',
    now() - interval '39 days',
    now() - interval '39 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Local bakeries are feeling a flour price squeeze',
    'local-bakeries-are-feeling-a-flour-price-squeeze-27',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    3179,
    now() - interval '43 days',
    now() - interval '43 days',
    now() - interval '43 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Motorcycle taxi apps are quietly rewriting commute times',
    'motorcycle-taxi-apps-are-quietly-rewriting-commute-times-28',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    644,
    now() - interval '15 days',
    now() - interval '15 days',
    now() - interval '15 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The barbershop chain scaling one franchise at a time',
    'the-barbershop-chain-scaling-one-franchise-at-a-time-29',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    1924,
    now() - interval '38 days',
    now() - interval '38 days',
    now() - interval '38 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why so many graduates are choosing trade over tech this year',
    'why-so-many-graduates-are-choosing-trade-over-tech-this-year-30',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    2826,
    now() - interval '3 days',
    now() - interval '3 days',
    now() - interval '3 days'
  );
  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'MIVA students push back on the new exam-fee structure',
    'miva-students-push-back-on-the-new-exam-fee-structure-31',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4537,
    now() - interval '14 days',
    now() - interval '14 days',
    now() - interval '14 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The unofficial guide to surviving TMA season',
    'the-unofficial-guide-to-surviving-tma-season-32',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    3454,
    now() - interval '31 days',
    now() - interval '31 days',
    now() - interval '31 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Inside the dorm-room startup pitching to real investors',
    'inside-the-dorm-room-startup-pitching-to-real-investors-33',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    3487,
    now() - interval '28 days',
    now() - interval '28 days',
    now() - interval '28 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why the library''s new booking system is causing chaos',
    'why-the-library-s-new-booking-system-is-causing-chaos-34',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. Nobody involved expected this to still be unresolved months later, but here we are. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    1015,
    now() - interval '22 days',
    now() - interval '22 days',
    now() - interval '22 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'A professor''s side project just got picked up nationally',
    'a-professor-s-side-project-just-got-picked-up-nationally-35',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    3576,
    now() - interval '9 days',
    now() - interval '9 days',
    now() - interval '9 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The student union election nobody saw coming',
    'the-student-union-election-nobody-saw-coming-36',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4628,
    now() - interval '29 days',
    now() - interval '29 days',
    now() - interval '29 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Campus wifi outages are now a running joke — and a real problem',
    'campus-wifi-outages-are-now-a-running-joke---and-a-real-prob-37',
    '<p>It began with a single post that a handful of neighbors shared before anyone official weighed in. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    1482,
    now() - interval '16 days',
    now() - interval '16 days',
    now() - interval '16 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'How one cohort turned a group chat into a tutoring network',
    'how-one-cohort-turned-a-group-chat-into-a-tutoring-network-38',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    1468,
    now() - interval '4 days',
    now() - interval '4 days',
    now() - interval '4 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The scholarship fund started by three final-year students',
    'the-scholarship-fund-started-by-three-final-year-students-39',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    3585,
    now() - interval '19 days',
    now() - interval '19 days',
    now() - interval '19 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why more students are commuting instead of relocating',
    'why-more-students-are-commuting-instead-of-relocating-40',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4864,
    now() - interval '4 days',
    now() - interval '4 days',
    now() - interval '4 days'
  );
  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'We keep calling it ''gist'' — maybe that''s the point',
    'we-keep-calling-it--gist----maybe-that-s-the-point-41',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4239,
    now() - interval '31 days',
    now() - interval '31 days',
    now() - interval '31 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Stop treating comment sections as an afterthought',
    'stop-treating-comment-sections-as-an-afterthought-42',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. Nobody involved expected this to still be unresolved months later, but here we are. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4994,
    now() - interval '5 days',
    now() - interval '5 days',
    now() - interval '5 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The quiet dignity of a well-run market stall',
    'the-quiet-dignity-of-a-well-run-market-stall-43',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4862,
    now() - interval '16 days',
    now() - interval '16 days',
    now() - interval '16 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why local news still matters more than the national cycle',
    'why-local-news-still-matters-more-than-the-national-cycle-44',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    4402,
    now() - interval '37 days',
    now() - interval '37 days',
    now() - interval '37 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'In defense of the long, boring council meeting',
    'in-defense-of-the-long--boring-council-meeting-45',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    3362,
    now() - interval '17 days',
    now() - interval '17 days',
    now() - interval '17 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'What we lose when every corner store becomes a chain',
    'what-we-lose-when-every-corner-store-becomes-a-chain-46',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    3874,
    now() - interval '1 days',
    now() - interval '1 days',
    now() - interval '1 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The case for reading the whole article, not just the headline',
    'the-case-for-reading-the-whole-article--not-just-the-headlin-47',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    1205,
    now() - interval '17 days',
    now() - interval '17 days',
    now() - interval '17 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why ''small'' stories are usually the important ones',
    'why--small--stories-are-usually-the-important-ones-48',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>As always, we want to hear from anyone closer to this than we are. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    3709,
    now() - interval '11 days',
    now() - interval '11 days',
    now() - interval '11 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'On writing about your own neighborhood without flattering it',
    'on-writing-about-your-own-neighborhood-without-flattering-it-49',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    968,
    now() - interval '20 days',
    now() - interval '20 days',
    now() - interval '20 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The comment I almost didn''t approve — and why I did',
    'the-comment-i-almost-didn-t-approve---and-why-i-did-50',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    2351,
    now() - interval '10 days',
    now() - interval '10 days',
    now() - interval '10 days'
  );
  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The five-a-side league quietly producing real talent',
    'the-five-a-side-league-quietly-producing-real-talent-51',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>The Gist will keep following this as it develops. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    5315,
    now() - interval '44 days',
    now() - interval '44 days',
    now() - interval '44 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why the community stadium renovation keeps stalling',
    'why-the-community-stadium-renovation-keeps-stalling-52',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    5316,
    now() - interval '6 days',
    now() - interval '6 days',
    now() - interval '6 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'A referee''s-eye view of the derby everyone''s still talking about',
    'a-referee-s-eye-view-of-the-derby-everyone-s-still-talking-a-53',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    5339,
    now() - interval '9 days',
    now() - interval '9 days',
    now() - interval '9 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The women''s league finally getting a real broadcast deal',
    'the-women-s-league-finally-getting-a-real-broadcast-deal-54',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    199,
    now() - interval '36 days',
    now() - interval '36 days',
    now() - interval '36 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Inside the boxing gym training champions before breakfast',
    'inside-the-boxing-gym-training-champions-before-breakfast-55',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. It began with a single post that a handful of neighbors shared before anyone official weighed in. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    4891,
    now() - interval '24 days',
    now() - interval '24 days',
    now() - interval '24 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why grassroots scouts are showing up to primary school matches',
    'why-grassroots-scouts-are-showing-up-to-primary-school-match-56',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    446,
    now() - interval '24 days',
    now() - interval '24 days',
    now() - interval '24 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The rivalry that started over a parking dispute, not football',
    'the-rivalry-that-started-over-a-parking-dispute--not-footbal-57',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. Nobody involved expected this to still be unresolved months later, but here we are. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published',
    auth_id,
    cat_id,
    3449,
    now() - interval '36 days',
    now() - interval '36 days',
    now() - interval '36 days'
  );
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'A coach''s 20-year unpaid project just got its first sponsor',
    'a-coach-s-20-year-unpaid-project-just-got-its-first-sponsor-58',
    '<p>It began with a single post that a handful of neighbors shared before anyone official weighed in. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    1589,
    now() - interval '2 days',
    now() - interval '2 days',
    now() - interval '2 days'
  );
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'The marathon route locals actually recommend running',
    'the-marathon-route-locals-actually-recommend-running-59',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    1005,
    now() - interval '45 days',
    now() - interval '45 days',
    now() - interval '45 days'
  );
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, published_at, created_at, updated_at)
  values (
    'Why ticket prices at the local derby just doubled',
    'why-ticket-prices-at-the-local-derby-just-doubled-60',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published',
    auth_id,
    cat_id,
    2984,
    now() - interval '30 days',
    now() - interval '30 days',
    now() - interval '30 days'
  );
end $$;
