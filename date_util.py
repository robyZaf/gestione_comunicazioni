from datetime import datetime

def difference_between_dates(date1: str, date2: str, format: str):
    # convert string to date object
    d1 = datetime.strptime(date1, format)
    d2 = datetime.strptime(date2, format)
    # difference between dates in timedelta
    delta = d2 - d1
    return delta.days
