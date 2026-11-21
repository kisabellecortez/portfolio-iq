CREATE TABLE securities (
    security_id SERIAL PRIMARY KEY,
    ticker VARCHAR(20) NOT NULL UNIQUE,
    security_type VARCHAR(20) NOT NULL
        CHECK (security_type IN ('Stock', 'ETF')),
    company_name VARCHAR(150),
    exchange VARCHAR(50),
    currency VARCHAR(3) NOT NULL,
    sector VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE portfolios (
    portfolio_id SERIAL PRIMARY KEY,
    portfolio_name VARCHAR(100) NOT NULL,
    description TEXT,
    base_currency VARCHAR(3) NOT NULL DEFAULT 'CAD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_portfolio_name UNIQUE (portfolio_name)
);

CREATE TABLE exchange_rates (
    exchange_rate_id SERIAL PRIMARY KEY,
    base_currency VARCHAR(3) NOT NULL,
    quote_currency VARCHAR(3) NOT NULL,
    exchange_rate NUMERIC(12, 6) NOT NULL
        CHECK (exchange_rate > 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_exchange_rate
        UNIQUE (base_currency, quote_currency),

    CONSTRAINT different_currencies
        CHECK (base_currency <> quote_currency)
);

CREATE TABLE portfolio_holdings (
    holding_id SERIAL PRIMARY KEY,
    portfolio_id INTEGER NOT NULL,
    security_id INTEGER NOT NULL,
    quantity NUMERIC(15, 4) NOT NULL
        CHECK (quantity > 0),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_holdings_portfolio
        FOREIGN KEY (portfolio_id)
        REFERENCES portfolios(portfolio_id),

    CONSTRAINT fk_holdings_security
        FOREIGN KEY (security_id)
        REFERENCES securities(security_id),

    CONSTRAINT unique_portfolio_security
        UNIQUE (portfolio_id, security_id)
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    portfolio_id INTEGER NOT NULL,
    security_id INTEGER NOT NULL,
    transaction_type VARCHAR(10) NOT NULL
        CHECK (transaction_type IN ('BUY', 'SELL')),
    quantity NUMERIC(15, 4) NOT NULL
        CHECK (quantity > 0),
    price_per_share NUMERIC(15, 4) NOT NULL
        CHECK (price_per_share > 0),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    commission NUMERIC(15, 4) NOT NULL DEFAULT 0
        CHECK (commission >= 0),

    CONSTRAINT fk_transactions_portfolio
        FOREIGN KEY (portfolio_id)
        REFERENCES portfolios(portfolio_id),

    CONSTRAINT fk_transactions_security
        FOREIGN KEY (security_id)
        REFERENCES securities(security_id)
);

CREATE TABLE historical_prices (
    price_id SERIAL PRIMARY KEY,
    security_id INTEGER NOT NULL,
    price_date DATE NOT NULL,
    open NUMERIC(15, 4),
    high NUMERIC(15, 4),
    low NUMERIC(15, 4),
    close NUMERIC(15, 4),
    adjusted_close NUMERIC(15, 4),
    volume BIGINT,

    CONSTRAINT fk_historical_prices_security
        FOREIGN KEY (security_id)
        REFERENCES securities(security_id),

    CONSTRAINT unique_security_price_date
        UNIQUE (security_id, price_date)
);

CREATE TABLE portfolio_metrics (
    metric_id SERIAL PRIMARY KEY,
    portfolio_id INTEGER NOT NULL,
    metric_date DATE NOT NULL,
    total_value NUMERIC(18, 4),
    total_invested NUMERIC(18, 4),
    gain_loss NUMERIC(18, 4),
    return_percentage NUMERIC(12, 6),
    volatility NUMERIC(12, 6),
    sharpe_ratio NUMERIC(12, 6),
    beta NUMERIC(12, 6),

    CONSTRAINT fk_metrics_portfolio
        FOREIGN KEY (portfolio_id)
        REFERENCES portfolios(portfolio_id),

    CONSTRAINT unique_portfolio_metric_date
        UNIQUE (portfolio_id, metric_date)
);

CREATE TABLE benchmarks (
  benchmark_id SERIAL PRIMARY KEY,
  benchmark_name VARCHAR(100) NOT NULL,
  ticker VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  currency VARCHAR(3) NOT NULL DEFAULT 'CAD',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE benchmark_historical_prices (
  benchmark_price_id SERIAL PRIMARY KEY,
  benchmark_id INTEGER NOT NULL,
  price_date DATE NOT NULL,
  close_price NUMERIC(18, 6) NOT NULL,
  
  CONSTRAINT fk_benchmark
    FOREIGN KEY (benchmark_id)
    REFERENCES benchmarks(benchmark_id),
    
  CONSTRAINT unique_benchmark_date
    UNIQUE (benchmark_id, price_date)
);

CREATE INDEX idx_transactions_portfolio
    ON transactions(portfolio_id);

CREATE INDEX idx_transactions_security
    ON transactions(security_id);

CREATE INDEX idx_transactions_date
    ON transactions(transaction_date);

CREATE INDEX idx_historical_prices_date
    ON historical_prices(price_date);

CREATE INDEX idx_portfolio_metrics_date
    ON portfolio_metrics(metric_date);
