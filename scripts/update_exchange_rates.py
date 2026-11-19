
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


def update_exchange_rates():
    # Download recent USD/CAD exchange rates
    data = yf.Ticker("USDCAD=X").history(
        period="5d",
        interval="1d"
    )

    if data.empty:
        raise ValueError("Unable to retrieve USD/CAD exchange rate")

    # Most recent available closing rate
    usd_cad = float(data["Close"].dropna().iloc[-1])

    if usd_cad <= 0:
        raise ValueError("Invalid USD/CAD exchange rate")

    cad_usd = 1 / usd_cad

    rates = [
        ("USD", "CAD", usd_cad),
        ("CAD", "USD", cad_usd)
    ]

    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.executemany("""
            INSERT INTO exchange_rates (
                base_currency,
                quote_currency,
                exchange_rate,
                last_updated
            )
            VALUES (%s, %s, %s, NOW())

            ON CONFLICT (base_currency, quote_currency)
            DO UPDATE SET
                exchange_rate = EXCLUDED.exchange_rate,
                last_updated = NOW();
        """, rates)

        conn.commit()

        print(f"USD/CAD: {usd_cad:.6f}")
        print(f"CAD/USD: {cad_usd:.6f}")
        print("Exchange rates updated successfully.")

    except Exception:
        conn.rollback()
        raise

    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    update_exchange_rates()
