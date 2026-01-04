# Modul statistik

import math

def mean(data):
    return sum(data) / len(data)

def var(data):
    m = mean(data)
    return sum((x - m) ** 2 for x in data) / len(data)

def std(data):
    return math.sqrt(var(data))

def median(data):
    data_sorted = sorted(data)
    n = len(data_sorted)
    mid = n // 2
    if n % 2 == 1:
        return data_sorted[mid]
    else:
        return (data_sorted[mid - 1] + data_sorted[mid]) / 2
