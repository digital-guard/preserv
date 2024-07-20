INSERT INTO optim.feature_type VALUES
  (100,'blockface',           'class', null,  'Block Face line.', '{"shortname_pt":"face de quadra","description_pt":"Face de quadra.","synonymous_pt":["face de quadra","quadras"]}'::jsonb),
  (101,'blockface_full',       'line', false, 'Block Face line, with all metadata (official name, optional code and others)', NULL),
  (102,'blockface_ext',        'line', true,  'Block Face line, with external metadata at cadvia_cmpl', NULL),
  (103,'blockface_none',       'line', false, 'Block Face line with no metadata', NULL)
;
