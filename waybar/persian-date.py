#!/usr/bin/env python3

"""Print the current Gregorian and Persian dates for Waybar."""

from datetime import datetime


GREGORIAN_WEEKDAYS = (
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
)
GREGORIAN_MONTHS = (
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
)
PERSIAN_MONTHS = (
    "Far",
    "Ord",
    "Kho",
    "Tir",
    "Mor",
    "Shahr",
    "Mehr",
    "Aba",
    "Aza",
    "Dey",
    "Bah",
    "Esf",
)


def gregorian_to_persian(year: int, month: int, day: int) -> tuple[int, int, int]:
    """Convert a Gregorian date to the arithmetic Persian calendar."""

    days_before_month = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)

    if year > 1600:
        persian_year = 979
        year -= 1600
    else:
        persian_year = 0
        year -= 621

    adjusted_year = year + 1 if month > 2 else year
    elapsed_days = (
        365 * year
        + (adjusted_year + 3) // 4
        - (adjusted_year + 99) // 100
        + (adjusted_year + 399) // 400
        - 80
        + day
        + days_before_month[month - 1]
    )

    persian_year += 33 * (elapsed_days // 12053)
    elapsed_days %= 12053
    persian_year += 4 * (elapsed_days // 1461)
    elapsed_days %= 1461

    if elapsed_days > 365:
        persian_year += (elapsed_days - 1) // 365
        elapsed_days = (elapsed_days - 1) % 365

    if elapsed_days < 186:
        persian_month = 1 + elapsed_days // 31
        persian_day = 1 + elapsed_days % 31
    else:
        persian_month = 7 + (elapsed_days - 186) // 30
        persian_day = 1 + (elapsed_days - 186) % 30

    return persian_year, persian_month, persian_day


def main() -> None:
    now = datetime.now()
    persian_year, persian_month, persian_day = gregorian_to_persian(
        now.year, now.month, now.day
    )
    gregorian_date = (
        f"{GREGORIAN_WEEKDAYS[now.weekday()]}, "
        f"{now.day:02d} {GREGORIAN_MONTHS[now.month - 1]} {now.year % 100:02d}"
    )
    persian_date = (
        f"{persian_day:02d} {PERSIAN_MONTHS[persian_month - 1]} "
        f"{persian_year % 100:02d}"
    )
    print(f"  {gregorian_date} | {persian_date}")


if __name__ == "__main__":
    main()
