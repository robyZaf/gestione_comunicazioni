from datetime import datetime

def difference_between_dates(date1: str, date2: str, format: str):
    # convert string to date object
    d1 = datetime.strptime(date1, format)
    d2 = datetime.strptime(date2, format)
    # difference between dates in timedelta
    delta = d2 - d1
    return delta.days

def is_date_include_between(lower_date: str, upper_date: str, date_to_check: str, format: str):
    return difference_between_dates(lower_date, date_to_check, format) >= 0 and difference_between_dates(date_to_check, upper_date, format) >= 0