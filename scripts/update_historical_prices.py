
import os
import yfinance as yf
import psycopg2
import pandas as pd
from dotenv import load_dotenv

load_dotenv()

# Database connection
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
            print(f"Downloading {ticker}...")

            # Download one year of daily prices
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

                # Skip incomplete records
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

            # Insert or update historical prices
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


if __name__ == "__main__":
    update_historical_prices()
