/// A map element, which associates data with a map layer.
/// This is used to keep track of data and change map layers accordingly.
class MapElement<DataType, LayerType> {
  /// The associated data of the map element.
  final DataType data;

  /// The associated map layer of the map element.
  final LayerType layer;

  /// Create a new map element.
  MapElement(this.data, this.layer);
}
