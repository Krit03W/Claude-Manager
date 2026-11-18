def subtotal(items):
    """items: list of (price, qty)."""
    total = 0
    for price, qty in items:
        total += price * qty
    return total


def apply_discount(amount, percent):
    """percent is 0-100."""
    return amount - amount * percent / 100


def shipping(amount):
    """Free shipping for orders of 1000 or more, otherwise 50."""
    if amount >= 1000:
        return 0
    return 50


def total(items, percent=0):
    s = apply_discount(subtotal(items), percent)
    return s + shipping(s)
