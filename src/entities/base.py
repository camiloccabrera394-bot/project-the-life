class IsometricEntity:
    """Clase base para todos los objetos del mundo con ordenamiento de profundidad Y-Sort."""
    __slots__ = ('x', 'y')
    
    def __init__(self, x, y):
        self.x = float(x)
        self.y = float(y)

    @property
    def depth(self):
        """El eje Y determina qué objeto está delante o detrás en la perspectiva 2.5D."""
        return self.y

    def update(self, *args, **kwargs):
        pass

    def draw(self, surface, *args, **kwargs):
        pass
