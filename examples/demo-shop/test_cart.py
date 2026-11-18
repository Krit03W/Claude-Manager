from cart import subtotal, apply_discount, shipping, total

def test_subtotal():
    assert subtotal([(100, 2), (50, 1)]) == 250

def test_discount():
    assert apply_discount(200, 10) == 180

def test_shipping_boundary():
    assert shipping(1000) == 0
    assert shipping(999) == 50

def test_total():
    assert total([(500, 2)], percent=10) == 950
