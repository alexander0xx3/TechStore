// pantalla_inicio.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final Function(String) onTapCategoria;
  final VoidCallback onGoToCart;

  const HomeScreen({
    super.key,
    required this.onTapCategoria,
    required this.onGoToCart,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _categorias = [
    "Todos",
    "Laptops",
    "PCs",
    "Monitores",
    "Periféricos",
    "Audio",
    "Componentes",
    "Almacenamiento",
    "Redes",
    "Accesorios",
    "Tablets",
    "Smartwatch",
    "Impresoras",
    "Proyectores",
    "Drones",
    "Cámaras",
    "Smart Home"
  ];
  String _categoriaSeleccionada = "Todos";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // --- Variables del Banner ---
  final PageController _pageController = PageController();
  Timer? _bannerTimer;
  int _totalBannerPages = 0;
  final ValueNotifier<int> _currentBannerPage = ValueNotifier(0);
  Stream<QuerySnapshot>? _productStream;

  @override
  void initState() {
    super.initState();
    _updateProductStream();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    _currentBannerPage.dispose();
    super.dispose();
  }

  // --- Lógica del Timer y Stream ---

  void _updateProductStream() {
    Query query = FirebaseFirestore.instance.collection('Productos');
    if (_categoriaSeleccionada != "Todos") {
      query = query.where('categoria', isEqualTo: _categoriaSeleccionada);
    }
    _productStream = query.snapshots();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_totalBannerPages == 0 || !_pageController.hasClients) return;
      int nextPage = (_currentBannerPage.value + 1) % _totalBannerPages;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _handleBannerInteraction(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _bannerTimer?.cancel();
    } else if (notification is ScrollEndNotification) {
      _startBannerTimer();
    }
  }

  String _convertirUrlDrive(String originalUrl) {
    if (originalUrl.contains('drive.google.com/file/d/')) {
      try {
        final parts = originalUrl.split('/d/');
        final fileId = parts[1].split('/')[0];
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      } catch (e) {
        return originalUrl;
      }
    }
    return originalUrl;
  }

  // --- Widgets del Banner ---
  Widget _buildDynamicBannerCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Productos')
          .where('esDestacado', isEqualTo: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerPlaceholder(
              child: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return _buildBannerPlaceholder(
              child: const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No hay promociones ahora mismo.',
                  textAlign: TextAlign.center),
            ),
          ));
        }

        final bannerDocs = snapshot.data!.docs;
        _totalBannerPages = bannerDocs.length;

        return Column(
          children: [
            Container(
              height: 180.0,
              margin: const EdgeInsets.only(top: 16.0),
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  _handleBannerInteraction(notification);
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _totalBannerPages,
                  onPageChanged: (index) {
                    _currentBannerPage.value = index;
                  },
                  itemBuilder: (context, index) {
                    final doc = bannerDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String localImageUrl =
                        _convertirUrlDrive(data['imagen'] ?? '');
                    final String localNombre = data['nombre'] ?? 'Producto';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: InkWell(
                        onTap: () => _mostrarDetallesProducto(
                            context,
                            doc.id,
                            localNombre,
                            double.tryParse(data['precio'].toString()) ?? 0.0,
                            localImageUrl,
                            data),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                _buildBannerImage(localImageUrl, localNombre)),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_totalBannerPages > 1)
              ValueListenableBuilder<int>(
                valueListenable: _currentBannerPage,
                builder: (context, currentPage, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        _totalBannerPages,
                        (index) => Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (Theme.of(context).primaryColor)
                                    .withOpacity(
                                        currentPage == index ? 0.9 : 0.4),
                              ),
                            )),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildBannerPlaceholder({required Widget child}) {
    return Container(
      height: 180.0,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
          color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }

  Widget _buildBannerImage(String imageUrl, String nombre) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: Center(
                  child: Icon(Icons.broken_image, color: Colors.grey[400]))),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : Container(color: Colors.grey[200]),
        ),
        Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8)
            ]))),
        Positioned(
          bottom: 12.0,
          left: 12.0,
          right: 12.0,
          child: Text(
            nombre,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- Widgets de UI (Search, Category, Filter) ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  })
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFiltroActivoChip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text('Mostrando: $_categoriaSeleccionada'),
        labelStyle: TextStyle(
            color: Theme.of(context).primaryColorDark,
            fontWeight: FontWeight.w500),
        avatar:
            Icon(Icons.filter_list, color: Theme.of(context).primaryColorDark),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        onDeleted: () {
          setState(() {
            _categoriaSeleccionada = "Todos";
            _updateProductStream();
          });
        },
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 60,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                final bool isSelected = categoria == _categoriaSeleccionada;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4.0, vertical: 8.0),
                  child: FilterChip(
                    label: Text(
                      categoria,
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w500),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _categoriaSeleccionada = categoria;
                          _updateProductStream();
                        });
                        widget.onTapCategoria(categoria);
                      }
                    },
                    backgroundColor: Theme.of(context).cardColor,
                    selectedColor: Theme.of(context).primaryColor,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: Colors.grey[300]),
        ],
      ),
    );
  }

  // --- Widgets de Grid y Productos ---

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _buildErrorState('Error al cargar productos');
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildLoadingGrid();
        final docs = snapshot.data!.docs;
        final filteredDocs = _searchQuery.isEmpty
            ? docs
            : docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nombre = data['nombre']?.toString().toLowerCase() ?? '';
                return nombre.startsWith(_searchQuery);
              }).toList();
        if (filteredDocs.isEmpty) return _buildEmptyState();

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final nombre = data['nombre'] ?? 'Sin nombre';
            final precio = double.tryParse(data['precio'].toString()) ?? 0.0;
            final originalUrl = data['imagen'] ?? '';
            final String imagenUrl = _convertirUrlDrive(originalUrl);

            return AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: 2,
              duration: const Duration(milliseconds: 375),
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _buildProductCard(
                      context, doc.id, nombre, precio, imagenUrl, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, String docId, String nombre,
      double precio, String imagenUrl, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _mostrarDetallesProducto(
              context, docId, nombre, precio, imagenUrl, data);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12))),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: (imagenUrl.isNotEmpty)
                      ? Image.network(
                          imagenUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : Center(
                                      child: CircularProgressIndicator(
                                          value: progress.expectedTotalBytes !=
                                                  null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null)),
                          errorBuilder: (_, __, ___) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    color: Colors.grey[400], size: 40),
                                const SizedBox(height: 4),
                                Text('Imagen no disponible',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 10)),
                              ]),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.image_not_supported,
                                  color: Colors.grey[400], size: 40),
                              const SizedBox(height: 4),
                              Text('Sin imagen',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 10)),
                            ]),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('S/ ${precio.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      InkWell(
                        onTap: () {
                          final productMap = Map<String, dynamic>.from(data);
                          productMap['id'] = docId;
                          productMap['imagen'] = imagenUrl;
                          addProductToCart(productMap);

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('Añadido al carrito')),
                                ],
                              ),
                              backgroundColor: Colors.black.withOpacity(0.8),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.0),
                              ),
                              action: null,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add_shopping_cart,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetallesProducto(
      BuildContext context,
      String docId,
      String nombre,
      double precio,
      String imagenUrl,
      Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20))),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                const Text('Detalles del Producto',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12)),
                        child: imagenUrl.isNotEmpty
                            ? Image.network(imagenUrl, fit: BoxFit.contain)
                            : const Icon(Icons.image_not_supported,
                                size: 60, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(nombre,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('S/ ${precio.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      if (data['descripcion'] != null) ...[
                        const Text('Descripción:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(data['descripcion'].toString(),
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14)),
                        const SizedBox(height: 16),
                      ],
                      if (data['categoria'] != null) ...[
                        const Text('Categoría:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Chip(
                            label: Text(data['categoria'].toString()),
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.1)),
                      ],
                    ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, -2))
                  ]),
              child: ElevatedButton(
                onPressed: () {
                  final productMap = Map<String, dynamic>.from(data);
                  productMap['id'] = docId;
                  productMap['imagen'] = imagenUrl;
                  addProductToCart(productMap);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(child: Text('Añadido al carrito')),
                        ],
                      ),
                      backgroundColor: Colors.black.withOpacity(0.8),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      action: null,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_shopping_cart),
                      SizedBox(width: 8),
                      Text('Agregar al Carrito')
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72),
      itemCount: 6,
      itemBuilder: (context, index) => Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()))),
        Container(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  height: 16, width: double.infinity, color: Colors.grey[200]),
              const SizedBox(height: 8),
              Container(height: 14, width: 80, color: Colors.grey[200]),
            ])),
      ])),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 16),
      Text(message,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: () => setState(() {}), child: const Text('Reintentar')),
    ]));
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 16),
      const Text('No se encontraron productos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(
        _searchQuery.isNotEmpty
            ? 'No hay resultados para "$_searchQuery"'
            : 'No hay productos en esta categoría',
        style: TextStyle(color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
      if (_searchQuery.isNotEmpty) ...[
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('Limpiar búsqueda')),
      ]
    ]));
  }

  // --- Método Build (Con Scroll Arreglado) ---
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_categoriaSeleccionada == "Todos") ...[
            _buildSearchBar(),
            _buildDynamicBannerCarousel(),
          ] else ...[
            _buildFiltroActivoChip(),
          ],
          _buildCategoryBar(),
          _buildProductGrid(),
        ],
      ),
    );
  }
}
