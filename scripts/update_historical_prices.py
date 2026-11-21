
import os
import yfinance as yf
import psycopg2
from dotenv import load_dotenv

load_dotenv()


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )


def update_historical_prices():
    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Retrieve all securities
        cursor.execute("""
            SELECT security_id, ticker
            FROM securities
            ORDER BY ticker;
        """)

        securities = cursor.fetchall()

        for security_id, ticker in securities:
            print(f"Downloading security {ticker}...")

            data = yf.Ticker(ticker).history(
                period="1y",
                interval="1d",
                auto_adjust=False,
                actions=False
            )

            if data.empty:
                print(f"No data returned for {ticker}")
                continue

            rows = []

            for date, price in data.iterrows():

                required = ["Open", "High", "Low", "Close", "Volume"]

                if price[required].isna().any():
                    continue

                adjusted_close = price.get("Adj Close", price["Close"])

                rows.append((
                    security_id,
                    date.date(),
                    float(price["Open"]),
                    float(price["High"]),
                    float(price["Low"]),
                    float(price["Close"]),
                    float(adjusted_close),
                    int(price["Volume"])
                ))

            cursor.executemany("""
                INSERT INTO historical_prices (
                    security_id,
                    price_date,
                    open,
                    high,
                    low,
                    close,
                    adjusted_close,
                    volume
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)

                ON CONFLICT (security_id, price_date)
                DO UPDATE SET
                    open = EXCLUDED.open,
                    high = EXCLUDED.high,
                    low = EXCLUDED.low,
                    close = EXCLUDED.close,
                    adjusted_close = EXCLUDED.adjusted_close,
                    volume = EXCLUDED.volume;
            """, rows)

            conn.commit()

            print(f"Inserted/updated {len(rows)} records for {ticker}")

    except Exception:
        conn.rollback()
        raise

    finally:
        cursor.close()
        conn.close()


def update_benchmark_historical_prices():
    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Retrieve all benchmarks
        cursor.execute("""
            SELECT benchmark_id, benchmark_name, ticker
            FROM benchmarks
            ORDER BY benchmark_name;
        """)

        benchmarks = cursor.fetchall()

        for benchmark_id, benchmark_name, ticker in benchmarks:
            print(f"Downloading benchmark {benchmark_name} ({ticker})...")

            data = yf.Ticker(ticker).history(
                period="1y",
                interval="1d",
                auto_adjust=False,
                actions=False
            )

            if data.empty:
                print(f"No data returned for benchmark {ticker}")
                continue

            rows = []

            for date, price in data.iterrows():

                if price["Close"] != price["Close"]:
                    continue

                rows.append((
                    benchmark_id,
                    date.date(),
                    float(price["Close"])
                ))

            cursor.executemany("""
                INSERT INTO benchmark_historical_prices (
                    benchmark_id,
                    price_date,
                    close_price
                )
                VALUES (%s, %s, %s)

                ON CONFLICT (benchmark_id, price_date)
                DO UPDATE SET
                    close_price = EXCLUDED.close_price;
            """, rows)

            conn.commit()

            print(
                f"Inserted/updated {len(rows)} records "
                f"for benchmark {benchmark_name}"
            )

    except Exception:
        conn.rollback()
        raise

    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    update_historical_prices()
    update_benchmark_historical_prices()
