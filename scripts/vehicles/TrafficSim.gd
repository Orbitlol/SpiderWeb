extends RefCounted
class_name TrafficSim

static func distant_transform(index: int, time: float) -> Transform3D:
	var x := CityLayout.CITY_ORIGIN + fposmod(float(index) * 18.0 + time * 7.0, CityLayout.GRID * CityLayout.BLOCK)
	var z := CityLayout.CITY_ORIGIN + float((index * 3) % 7) * CityLayout.BLOCK + 8.0
	return Transform3D(Basis.IDENTITY, Vector3(x, 0.7, z))
