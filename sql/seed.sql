BEGIN;

INSERT INTO portfolios (
    portfolio_name,
    description,
    base_currency,
    created_at
)
VALUES
(
    'Growth and technology portfolio',
    'Focus on technology companies, AI infrastructure, semiconductor demand, and long-term capital appreciation.',
    'USD',
    NOW()
),
(
    'Dividend and Financial Income Portfolio',
    'Emphasize established businesses, financial institutions, dividend income, and relatively defensive sectors.',
    'USD',
    NOW()
),
(
    'Diversified Core Portfolio',
    'Provide broad market exposure rather than relying on individual stock selection.',
    'CAD',
    NOW()
)
ON CONFLICT (portfolio_name) DO NOTHING;

INSERT INTO securities (
    ticker,
    security_type,
    company_name,
    exchange,
    currency,
    sector
)
VALUES
    ('AAPL', 'Stock', 'Apple Inc.', 'NMS', 'USD', 'Technology'),
    ('AMD', 'Stock', 'Advanced Micro Devices, Inc.', 'NMS', 'USD', 'Technology'),
    ('JNJ', 'Stock', 'Johnson & Johnson', 'NYQ', 'USD', 'Healthcare'),
    ('MFC.TO', 'Stock', 'Manulife Financial Corporation', 'TOR', 'CAD', 'Financial Services'),
    ('MRVL', 'Stock', 'Marvell Technology, Inc.', 'NMS', 'USD', 'Technology'),
    ('MU', 'Stock', 'Micron Technology, Inc.', 'NMS', 'USD', 'Technology'),
    ('NVDA', 'Stock', 'NVIDIA Corporation', 'NMS', 'USD', 'Technology'),
    ('PG', 'Stock', 'The Procter & Gamble Company', 'NYQ', 'USD', 'Consumer Defensive'),
    ('SLF.TO', 'Stock', 'Sun Life Financial Inc.', 'TOR', 'CAD', 'Financial Services'),
    ('SNDK', 'Stock', 'Sandisk Corporation', 'NMS', 'USD', 'Technology'),
    ('TSM', 'Stock', 'Taiwan Semiconductor Manufacturing Company Limited', 'NYQ', 'USD', 'Technology'),
    ('VEQT.TO', 'ETF', 'Vanguard All-Equity ETF Portfolio', 'TOR', 'CAD', NULL),
    ('ZEB.TO', 'ETF', 'BMO Equal Weight Banks Index ETF', 'TOR', 'CAD', NULL),
    ('ZSP.TO', 'ETF', 'BMO S&P 500 Index ETF', 'TOR', 'CAD', NULL)
ON CONFLICT (ticker) DO NOTHING;

INSERT INTO transactions (
    portfolio_id,
    security_id,
    transaction_type,
    quantity,
    price_per_share,
    transaction_date,
    commission
)
SELECT
    p.portfolio_id,
    s.security_id,
    'BUY',
    v.quantity,
    v.price_per_share,
    v.transaction_date,
    0.00
FROM (
    VALUES
        ('Growth and technology portfolio', 'AAPL', 5, 339.12, DATE '2026-11-06'),
        ('Growth and technology portfolio', 'AMD', 5, 443.92, DATE '2026-11-06'),
        ('Growth and technology portfolio', 'MRVL', 15, 144.7662, DATE '2026-11-06'),
        ('Growth and technology portfolio', 'MU', 5, 706.4992, DATE '2026-11-06'),
        ('Growth and technology portfolio', 'NVDA', 25, 191.2655, DATE '2026-11-06'),
        ('Growth and technology portfolio', 'SNDK', 20, 897.34, DATE '2026-11-06'),
        ('Growth and technology portfolio', 'TSM', 5, 380.00, DATE '2026-11-06'),

        ('Dividend and Financial Income Portfolio', 'JNJ', 10, 273.6822, DATE '2026-11-04'),
        ('Dividend and Financial Income Portfolio', 'MFC.TO', 5, 63.84, DATE '2026-11-04'),
        ('Dividend and Financial Income Portfolio', 'PG', 15, 167.1752, DATE '2026-11-04'),
        ('Dividend and Financial Income Portfolio', 'SLF.TO', 20, 113.96, DATE '2026-11-04'),
        ('Dividend and Financial Income Portfolio', 'ZEB.TO', 5, 77.65, DATE '2026-11-04'),

        ('Diversified Core Portfolio', 'VEQT.TO', 50, 61.79, DATE '2026-11-04'),
        ('Diversified Core Portfolio', 'ZSP.TO', 50, 117.93, DATE '2026-11-04')
) AS v(portfolio_name, ticker, quantity, price_per_share, transaction_date)
JOIN portfolios p
    ON LOWER(p.portfolio_name) = LOWER(v.portfolio_name)
JOIN securities s
    ON s.ticker = v.ticker;

INSERT INTO portfolio_holdings (
    portfolio_id,
    security_id,
    quantity,
    updated_at
)
SELECT
    portfolio_id,
    security_id,
    SUM(
        CASE
            WHEN transaction_type = 'BUY' THEN quantity
            WHEN transaction_type = 'SELL' THEN -quantity
            ELSE 0
        END
    ) AS quantity,
    NOW()
FROM transactions
GROUP BY portfolio_id, security_id
HAVING SUM(
    CASE
        WHEN transaction_type = 'BUY' THEN quantity
        WHEN transaction_type = 'SELL' THEN -quantity
        ELSE 0
    END
) <> 0;

INSERT INTO benchmarks (
    benchmark_name,
    ticker,
    description,
    currency
)
VALUES
(
    'S&P/TSX Composite',
    '^GSPTSE',
    'Broad Canadian equity market index',
    'CAD'
),
(
    'S&P 500',
    '^GSPC',
    'Tracks 500 leading US companies',
    'USD'
),
(
    'NASDAQ Composite',
    '^IXIC',
    'Broad index of securities listed on Nasdaq',
    'USD'
),
(
    'Russell 2000',
    '^RUT',
    'Tracks small-cap US companies',
    'USD'
),
(
    'MSCI World',
    'URTH',
    'iShares MSCI World ETF proxy',
    'USD'
),
(
    'MSCI Emerging Markets',
    'EEM',
    'iShares MSCI Emerging Markets ETF proxy',
    'USD'
),
(
    'FTSE Canada Universe Bond',
    'XBB.TO',
    'iShares Core Canadian Universe Bond ETF proxy',
    'CAD'
);

COMMIT;
