// ignore_for_file: file_names, use_build_context_synchronously, avoid_print, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class ProductList {
  final int id;
  final String name;

  ProductList({
    required this.id,
    required this.name,
  });
}

class Product {
  final int ProductId;
  String ProductCode;
  String ProductName;
  Product(
      {required this.ProductId,
      required this.ProductCode,
      required this.ProductName});
}

class ProductMultiLevelDropDown extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  ProductMultiLevelDropDown({
    super.key,
  });

  @override
  State<ProductMultiLevelDropDown> createState() =>
      _ProductMultiLevelDropDownState();
}

class _ProductMultiLevelDropDownState extends State<ProductMultiLevelDropDown> {
  List<Product> products = [
    Product(ProductId: 1, ProductCode: "", ProductName: "3 Ply Mask"),
  ];
  List<Product> selectedProducts = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final items = products
        .map((prod) => MultiSelectItem<Product>(prod, prod.ProductName))
        .toList();
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
        height: null,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 10, left: 0, right: 0),
        child: Column(
          children: <Widget>[
            MultiSelectDialogField(
              searchable: true,
              listType: MultiSelectListType.LIST,
              separateSelectedItems: false,
              items: items,
              title: const Text("Products"),
              selectedColor: const Color(0xff2ca9df),
              buttonIcon: const Icon(
                Icons.search,
                color: Color(0xff2ca9df),
              ),
              buttonText: const Text(
                "Products",
                style: TextStyle(
                  color: Color(0xFF8F8F8F),
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              onConfirm: (results) {
                setState(() {
                  selectedProducts = results;
                });
              },
              selectedItemsTextStyle: const TextStyle(
                color: Color(0xFF8F8F8F),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  @override
  void dispose() {
    // initialParticipant = [];
    super.dispose();
  }
}
