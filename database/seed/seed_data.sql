USE aml_analytics;

-- =====================================================================
-- Dev-only synthetic seed data.
-- NOT a stored procedure — this is test fixture data, not business logic.
-- In production, accounts/transactions are populated by the bank's core
-- system feed. This script exists purely so procedures can be tested
-- against realistic data during development.
-- =====================================================================

-- Accounts across a few segments, so peer-group cohorts have members
INSERT INTO accounts (account_id, customer_type, region, product, opened_at) VALUES
  ('ACC2001', 'retail', 'APAC', 'current_account', '2022-03-01'),
  ('ACC2002', 'retail', 'APAC', 'current_account', '2022-05-14'),
  ('ACC2003', 'retail', 'APAC', 'current_account', '2023-01-20'),
  ('ACC2004', 'corporate', 'EU', 'trade_finance', '2021-11-09'),
  ('ACC2005', 'corporate', 'EU', 'trade_finance', '2022-08-17'),
  ('ACC2006', 'retail', 'EU', 'savings_account', '2023-02-02');

-- Normal, regular transaction activity for ACC2001 (steady small transfers)
INSERT INTO transactions (sender_account, receiver_account, amount, currency, country, payment_type, txn_timestamp, label) VALUES
  ('ACC2001', 'ACC2002', 450.00, 'USD', 'US', 'ach', NOW() - INTERVAL 5 DAY,  'normal'),
  ('ACC2001', 'ACC2002', 480.00, 'USD', 'US', 'ach', NOW() - INTERVAL 12 DAY, 'normal'),
  ('ACC2001', 'ACC2003', 500.00, 'USD', 'US', 'ach', NOW() - INTERVAL 19 DAY, 'normal'),
  ('ACC2001', 'ACC2002', 470.00, 'USD', 'US', 'ach', NOW() - INTERVAL 26 DAY, 'normal'),
  ('ACC2001', 'ACC2003', 460.00, 'USD', 'US', 'ach', NOW() - INTERVAL 33 DAY, 'normal'),
  -- Deliberate anomaly: ~30x the account's normal amount, unusual country/payment type
  ('ACC2001', 'ACC2004', 15000.00, 'USD', 'AE', 'wire', NOW() - INTERVAL 2 DAY, NULL);

-- Corporate peer group: similar mid-size trade finance activity
INSERT INTO transactions (sender_account, receiver_account, amount, currency, country, payment_type, txn_timestamp, label) VALUES
  ('ACC2004', 'ACC2005', 8000.00, 'EUR', 'DE', 'wire', NOW() - INTERVAL 4 DAY,  'normal'),
  ('ACC2005', 'ACC2004', 7600.00, 'EUR', 'DE', 'wire', NOW() - INTERVAL 15 DAY, 'normal'),
  ('ACC2004', 'ACC2005', 8200.00, 'EUR', 'FR', 'wire', NOW() - INTERVAL 22 DAY, 'normal');

-- Retail savings account with light activity
INSERT INTO transactions (sender_account, receiver_account, amount, currency, country, payment_type, txn_timestamp, label) VALUES
  ('ACC2006', 'ACC2002', 200.00, 'EUR', 'DE', 'ach', NOW() - INTERVAL 8 DAY,  'normal'),
  ('ACC2006', 'ACC2003', 220.00, 'EUR', 'DE', 'ach', NOW() - INTERVAL 21 DAY, 'normal');
  
  
CALL sp_baseline_refresh(NULL, NULL);
SELECT * FROM account_baseline ORDER BY account_id;

INSERT INTO peer_group (group_name, segment_criteria) VALUES
  ('Retail APAC Current Accounts', 'customer_type=retail, region=APAC, product=current_account'),
  ('Corporate EU Trade Finance', 'customer_type=corporate, region=EU, product=trade_finance');


SELECT user_id, full_name, email, role
FROM users;

SELECT COUNT(*) AS total_users
FROM users;


INSERT INTO users (full_name, email, password_hash, role, is_active)
VALUES
(
'Demo Analyst',
'analyst@aml-demo.com',
'$2b$12$esG7.6wVjGh.X360fl8u0OQ49fJXW7A9KJhhkScMAO24z4LaSTgDa',
'analyst',
1
),
(
'Demo Manager',
'manager@aml-demo.com',
'$2b$12$l0GmI70tqyr38eLCnL6U7.cU6IA52pDVaEsj7kxLZCxXVREC4a776',
'manager',
1
);