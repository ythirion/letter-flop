-- =============================================================
-- Letterflop — Schéma de base de données
-- =============================================================

CREATE TABLE IF NOT EXISTS movie_logs (
    id          BIGSERIAL PRIMARY KEY,
    tmdb_id     INTEGER       NOT NULL,
    title       VARCHAR(255)  NOT NULL,
    year        INTEGER,
    poster_path VARCHAR(500),
    director    VARCHAR(255),
    synopsis    TEXT,
    rating      NUMERIC(3, 1) NOT NULL,
    watched_at  DATE          NOT NULL,
    comment     VARCHAR(500),
    created_at  TIMESTAMP DEFAULT NOW()
);

-- =============================================================
-- Données de démonstration (~330 visionnages)
-- =============================================================

WITH films(tmdb_id, title, year, poster, director, synopsis) AS (
  VALUES
    (550,    'Fight Club',                    1999, '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', 'David Fincher',          'Un employé de bureau insomniaque et un vendeur de savon fondent un club de combat clandestin.'),
    (13,     'Forrest Gump',                  1994, '/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg', 'Robert Zemeckis',        'La vie extraordinaire d''un homme ordinaire du Sud des États-Unis.'),
    (680,    'Pulp Fiction',                  1994, '/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg', 'Quentin Tarantino',      'Les histoires entrelacées de criminels et de gangsters à Los Angeles.'),
    (238,    'Le Parrain',                    1972, '/3bhkrj58Vtu7enYsLegHnDmni6k.jpg', 'Francis Ford Coppola',   'Le patriarche d''une famille mafieuse transfère son empire à son fils réticent.'),
    (278,    'Les Évadés',                    1994, '/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg', 'Frank Darabont',         'Deux hommes se lient d''amitié sur plusieurs années dans une prison.'),
    (155,    'The Dark Knight',               2008, '/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'Christopher Nolan',      'Batman affronte le Joker, un criminel anarchiste qui sème la terreur à Gotham.'),
    (27205,  'Inception',                     2010, '/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', 'Christopher Nolan',      'Un voleur qui s''introduit dans les rêves se voit offrir une chance de rédemption.'),
    (157336, 'Interstellar',                  2014, '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', 'Christopher Nolan',      'Des astronautes voyagent à travers un trou de ver en quête d''un nouveau foyer.'),
    (244786, 'Whiplash',                      2014, '/7fn624j5lj3xTme2SgiLCeuedmO.jpg', 'Damien Chazelle',        'Un jeune batteur ambitieux étudie sous un professeur de jazz redoutablement exigeant.'),
    (313369, 'La La Land',                    2016, '/uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg', 'Damien Chazelle',        'Un acteur et une pianiste tombent amoureux à Los Angeles en poursuivant leurs rêves.'),
    (603,    'The Matrix',                    1999, '/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg', 'Lana et Lilly Wachowski','Un hacker découvre que la réalité telle qu''il la connaît est une simulation.'),
    (129,    'Spirited Away',                 2001, '/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg', 'Hayao Miyazaki',         'Une fillette se retrouve dans un monde fantastique après que ses parents ont été ensorcelés.'),
    (496243, 'Parasite',                      2019, '/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg', 'Bong Joon-ho',           'Une famille pauvre s''infiltre progressivement dans la vie d''une famille riche.'),
    (372058, 'Your Name',                     2016, '/q719jXXEzOoYaps6babgKnONONX.jpg', 'Makoto Shinkai',         'Deux lycéens découvrent qu''ils échangent leurs corps dans leurs rêves.'),
    (329865, 'Premier Contact',               2016, '/x2FJsf1ElAgr63Y3PNPtJrcmpoe.jpg', 'Denis Villeneuve',       'Une linguiste est recrutée pour communiquer avec des extraterrestres.'),
    (335984, 'Blade Runner 2049',             2017, '/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg', 'Denis Villeneuve',       'Un nouveau blade runner découvre un secret qui remet en cause la société.'),
    (76341,  'Mad Max : Fury Road',           2015, '/8tZYtuWezp8JbcsvHYO0O46tFbo.jpg', 'George Miller',          'Dans un monde post-apocalyptique, Max s''allie à Furiosa pour fuir un tyran.'),
    (324857, 'Spider-Man : New Generation',   2018, '/iiZZdoQBEYBv6id8su7ImL0oCbD.jpg', 'Bob Persichetti',        'Un jeune adolescent devient Spider-Man et rencontre ses alter ego d''autres dimensions.'),
    (475557, 'Joker',                         2019, '/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg', 'Todd Phillips',          'Un comédien raté bascule dans la folie et devient un symbole de rébellion.'),
    (1124,   'Le Prestige',                   2006, '/5MXyQfz8xUP3dIFPTubhTsbFY6N.jpg', 'Christopher Nolan',      'Deux magiciens s''affrontent dans une rivalité destructrice.'),
    (807,    'Seven',                         1995, '/6yoghtyTpznpBik8EngEmJskVnS.jpg', 'David Fincher',          'Deux détectives traquent un tueur en série qui s''inspire des sept péchés capitaux.'),
    (769,    'Les Affranchis',                1990, '/6QMHMhJAQEt3KgvHmOoS9qsLVwy.jpg', 'Martin Scorsese',        'Un fils de famille entre dans la mafia new-yorkaise et gravit ses échelons.'),
    (98,     'Gladiator',                     2000, '/ty8TGRuvJLPUmAR1H1nRIsgwvim.jpg', 'Ridley Scott',           'Un général romain trahi devient gladiateur pour se venger de l''usurpateur.'),
    (120,    'La Fraternité de l''Anneau',    2001, '/6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg', 'Peter Jackson',          'Un hobbit entreprend un voyage périlleux pour détruire l''Anneau Unique.'),
    (121,    'Les Deux Tours',                2002, '/5VTN0pR8gcqV3EPUHHfMGnJYspN.jpg', 'Peter Jackson',          'La Communauté de l''Anneau se sépare et affronte de nouvelles menaces.'),
    (122,    'Le Retour du Roi',              2003, '/rCzpDGLbOoPwLjy3OAm5NUPOTrC.jpg', 'Peter Jackson',          'La guerre pour la Terre du Milieu entre dans sa phase finale.'),
    (11,     'Star Wars : Un Nouvel Espoir',  1977, '/6FfCtAuVAW8XJjZ7eWeLibRLWTw.jpg', 'George Lucas',           'Un jeune fermier se joint à la Rébellion pour combattre l''Empire Galactique.'),
    (1891,   'L''Empire contre-attaque',      1980, '/2l05cFWJacyIsTpsqSgH0wQXe4V.jpg', 'Irvin Kershner',         'Luke Skywalker s''entraîne auprès de Yoda tandis que l''Empire traque ses amis.'),
    (489,    'Will Hunting',                  1997, '/bABCDF5ceosqgzestEDMsrIlirc.jpg', 'Gus Van Sant',           'Un jeune homme surdoué issu des quartiers défavorisés de Boston découvre son potentiel.'),
    (274,    'Le Silence des Agneaux',        1991, '/rplLJ2hPcOQmkFhTqUte0MkosKe.jpg', 'Jonathan Demme',         'Une agente du FBI consulte un brillant tueur en série pour attraper un autre meurtrier.'),
    (240,    'Le Parrain 2',                  1974, '/hek3koDUyRQk7FIhPXsa6mT2Zc3.jpg', 'Francis Ford Coppola',   'Le récit parallèle des jeunes années de Vito Corleone et l''ascension de son fils Michael.'),
    (424,    'La Liste de Schindler',         1993, '/sF1U4EUQKB5Ckza8dIlfv3M7BHv.jpg', 'Steven Spielberg',       'Un industriel allemand sauve la vie de plus d''un millier de Juifs polonais.'),
    (637,    'La vie est belle',              1997, '/74hLDKjD5aGYOotO6esUVaeISa2.jpg', 'Roberto Benigni',        'Un père juif protège son fils dans un camp de concentration en lui faisant croire à un jeu.'),
    (510,    'Vol au-dessus d''un nid de coucou', 1975, '/3jcbDmRFiQ83drXNOvRDeKHxS0C.jpg', 'Milos Forman',      'Un détenu simule la maladie mentale et défie l''ordre dans un asile psychiatrique.'),
    (77,     'Memento',                       2000, '/yuNs09hvpHVU1cBTCAk9zxsL2oW.jpg', 'Christopher Nolan',      'Un homme atteint d''amnésie tente de retrouver le meurtrier de sa femme.'),
    (11216,  'Cinema Paradiso',               1988, '/8SRUfRUi6x4O68n0VCbDNRa6iGL.jpg', 'Giuseppe Tornatore',     'Un réalisateur se souvient de son enfance dans un village sicilien et de son amour du cinéma.'),
    (346364, 'Ça',                            2017, '/9E2y5Q7WlCCsy9V7OT7UBMHAK1E.jpg', 'Andy Muschietti',        'Des enfants affrontent une entité maléfique qui terrorise leur ville sous la forme d''un clown.'),
    (9806,   'Les Indestructibles',           2004, '/2LqaLgcgFVLfIlQeXVTezm3ZgJl.jpg', 'Brad Bird',              'Une famille de super-héros doit masquer ses pouvoirs pour vivre normalement.'),
    (348,    'Alien',                         1979, '/vfrQk5IPloGg1v9Rzbh2Eg3VGyM.jpg', 'Ridley Scott',           'L''équipage d''un vaisseau spatial rencontre une forme de vie extraterrestre mortelle.'),
    (218,    'Terminator',                    1984, '/qvktm0BHcnmDpul4Hz01GIazWPr.jpg', 'James Cameron',          'Un cyborg est envoyé dans le passé pour tuer la mère d''un futur chef de la résistance.')
),
ratings(r, pos) AS (
  VALUES (1.5,0),(2.0,1),(2.5,2),(3.0,3),(3.5,4),(3.5,5),(4.0,6),(4.0,7),(4.5,8),(4.5,9),(4.5,10),(5.0,11)
),
comments(c, pos) AS (
  VALUES
    ('Absolument magistral.',0),
    ('Un chef-d''œuvre indémodable.',1),
    ('Ça m''a laissé sans voix.',2),
    ('Revu avec encore plus de plaisir.',3),
    ('Pas autant aimé que la première fois.',4),
    ('Une claque visuelle.',5),
    ('L''OST est incroyable.',6),
    ('Le twist final est dingue.',7),
    ('À voir absolument.',8),
    (NULL,9),
    (NULL,10),
    (NULL,11),
    (NULL,12),
    (NULL,13)
)
INSERT INTO movie_logs (tmdb_id, title, year, poster_path, director, synopsis, rating, watched_at, comment)
SELECT
  f.tmdb_id,
  f.title,
  f.year,
  'https://image.tmdb.org/t/p/original' || f.poster,
  f.director,
  f.synopsis,
  (SELECT r FROM ratings WHERE pos = ((f.tmdb_id * 7 + gs.n * 13) % 12)),
  DATE '2022-03-01' + (((f.tmdb_id % 97) * 3 + gs.n * 37) % 1140 || ' days')::interval,
  (SELECT c FROM comments WHERE pos = ((f.tmdb_id + gs.n * 11) % 14))
FROM films f
CROSS JOIN generate_series(0, 7) AS gs(n);

-- Visionnages supplémentaires explicites pour les films les plus aimés
INSERT INTO movie_logs (tmdb_id, title, year, poster_path, director, synopsis, rating, watched_at, comment) VALUES
  (550,    'Fight Club',        1999, 'https://image.tmdb.org/t/p/original/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', 'David Fincher',          'Un employé de bureau insomniaque et un vendeur de savon fondent un club de combat clandestin.', 5.0, '2024-11-10', 'Encore meilleur en connaissant la fin.'),
  (550,    'Fight Club',        1999, 'https://image.tmdb.org/t/p/original/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', 'David Fincher',          'Un employé de bureau insomniaque et un vendeur de savon fondent un club de combat clandestin.', 4.5, '2023-06-14', 'Toujours aussi percutant.'),
  (155,    'The Dark Knight',   2008, 'https://image.tmdb.org/t/p/original/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'Christopher Nolan',      'Batman affronte le Joker, un criminel anarchiste qui sème la terreur à Gotham.',             5.0, '2024-08-20', 'Heath Ledger est irremplaçable.'),
  (155,    'The Dark Knight',   2008, 'https://image.tmdb.org/t/p/original/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'Christopher Nolan',      'Batman affronte le Joker, un criminel anarchiste qui sème la terreur à Gotham.',             5.0, '2022-12-01', NULL),
  (680,    'Pulp Fiction',      1994, 'https://image.tmdb.org/t/p/original/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg', 'Quentin Tarantino',      'Les histoires entrelacées de criminels et de gangsters à Los Angeles.',                     5.0, '2025-01-15', 'Le meilleur Tarantino.'),
  (27205,  'Inception',         2010, 'https://image.tmdb.org/t/p/original/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', 'Christopher Nolan',      'Un voleur qui s''introduit dans les rêves se voit offrir une chance de rédemption.',         4.5, '2024-03-22', 'La toupie tourne encore dans ma tête.'),
  (278,    'Les Évadés',        1994, 'https://image.tmdb.org/t/p/original/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg', 'Frank Darabont',         'Deux hommes se lient d''amitié sur plusieurs années dans une prison.',                      5.0, '2023-11-05', 'Le meilleur film de tous les temps ?'),
  (496243, 'Parasite',          2019, 'https://image.tmdb.org/t/p/original/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg', 'Bong Joon-ho',           'Une famille pauvre s''infiltre progressivement dans la vie d''une famille riche.',            5.0, '2024-05-18', 'La cave m''a scotché.'),
  (13,     'Forrest Gump',      1994, 'https://image.tmdb.org/t/p/original/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg', 'Robert Zemeckis',        'La vie extraordinaire d''un homme ordinaire du Sud des États-Unis.',                       4.0, '2024-10-22', NULL),
  (19404,  'DDLJ',              1995, 'https://image.tmdb.org/t/p/original/2CAL2433ZeIihfX1Hb2139CX0pW.jpg', 'Aditya Chopra',          'Deux Indiens de la diaspora tombent amoureux lors d''un voyage en Europe.',                  3.5, '2024-09-05', 'Premier Bollywood que je regarde !'),
  (238,    'Le Parrain',        1972, 'https://image.tmdb.org/t/p/original/3bhkrj58Vtu7enYsLegHnDmni6k.jpg', 'Francis Ford Coppola',   'Le patriarche d''une famille mafieuse transfère son empire à son fils réticent.',           4.5, '2024-07-01', NULL);
