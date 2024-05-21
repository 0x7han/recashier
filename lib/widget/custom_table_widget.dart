import 'package:flutter/material.dart';

class CustomTableHeaderWidget extends StatelessWidget {
  final bool isAction;
  final double? width;
  final String label;
  final void Function()? onPressed;
  const CustomTableHeaderWidget(
      {super.key, this.isAction = false, this.width, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8, vertical: 16);
    final TextStyle? textTheme = Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600);
    return width == null
        ? Expanded(
            child: Container(
              padding: padding,
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 2, color: colorScheme.primaryContainer))),
              child: Row(
                mainAxisAlignment: isAction ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: textTheme,),
                  
                  isAction ? SizedBox() : SizedBox(
                            width: 20,
                            height: 20,
                            child: IconButton.filledTonal(
                                padding: EdgeInsets.all(0),
                                iconSize: 16,
                                onPressed: onPressed,
                                icon: Icon(Icons.sort)),
                          ),
                          
                ],
              ),
            ),
          )
        : Container(
            width: width,
            padding: padding,
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 2, color: colorScheme.primaryContainer))),
            child: Row(
              mainAxisAlignment: isAction ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: textTheme,),
                
                isAction ? SizedBox() : SizedBox(
                            width: 20,
                            height: 20,
                            child: IconButton.filledTonal(
                                padding: EdgeInsets.all(0),
                                iconSize: 16,
                                onPressed: onPressed,
                                icon: Icon(Icons.sort)),
                          ),
              ],
            ),
          );
  }
}

class CustomTableBodyWidget extends StatelessWidget {
  final double? width;
  final String label;
  const CustomTableBodyWidget({super.key, this.width, required this.label});

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = EdgeInsets.fromLTRB(8, 2, 8, 2);
    final EdgeInsets margin = EdgeInsets.symmetric(vertical: 4);
    return width == null
        ? Expanded(
            child: Container(
              padding: padding,
              margin: margin,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(label),
                  ],
                ),
              ),
            ),
          )
        : Container(
            width: width,
            padding: padding,
            margin: margin,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(label),
                ],
              ),
            ),
          );
  }
}

class CustomTableBodyActionWidget extends StatelessWidget {
  final bool isWriteable;
  final double? width;
  final void Function() onPressedDetail;
  final void Function()? onPressedEdit;
  final void Function()? onPressedDelete;
  const CustomTableBodyActionWidget(
      {super.key,
      required this.isWriteable,
      this.width,
      required this.onPressedDetail,
      this.onPressedEdit,
      this.onPressedDelete});

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = EdgeInsets.fromLTRB(8, 2, 8, 2);
    final EdgeInsets margin = EdgeInsets.symmetric(vertical: 4);
    return width == null
        ? Expanded(
            child: Container(
              margin: margin,
              padding: padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton.filledTonal(
                      onPressed: onPressedDetail, icon: Icon(Icons.notes)),
                  isWriteable
                      ? Row(
                          children: [
                            IconButton.filledTonal(
                                onPressed: onPressedEdit,
                                icon: Icon(Icons.edit_attributes)),
                            SizedBox(
                              width: 8,
                            ),
                            IconButton.filledTonal(
                                onPressed: onPressedDelete,
                                icon: Icon(Icons.delete)),
                          ],
                        )
                      : SizedBox(),
                ],
              ),
            ),
          )
        : Container(
            margin: margin,
            width: width,
            padding: padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton.filledTonal(
                      padding: EdgeInsets.all(0),
                      iconSize: 20,
                      onPressed: onPressedDetail,
                      icon: Icon(Icons.notes)),
                ),
                isWriteable
                    ? Row(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton.filledTonal(
                                padding: EdgeInsets.all(0),
                                iconSize: 20,
                                onPressed: onPressedEdit,
                                icon: Icon(Icons.edit_attributes)),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton.filledTonal(
                                padding: EdgeInsets.all(0),
                                iconSize: 20,
                                onPressed: onPressedDelete,
                                icon: Icon(Icons.delete)),
                          ),
                        ],
                      )
                    : SizedBox(),
              ],
            ),
          );
  }
}

class CustomTableBodyContainer extends StatelessWidget {
  final bool isOod;
  final List<Widget> bodies;
  const CustomTableBodyContainer({super.key, required this.isOod, required this.bodies});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: isOod ? colorScheme.secondaryContainer.withOpacity(0.5) : Colors.transparent,
      child: Row(
        children: bodies,
      ),
    );
  }
}

class CustomTableWidget extends StatelessWidget {
  final List<CustomTableHeaderWidget> headers;
  final List<CustomTableBodyContainer> bodies;
  const CustomTableWidget(
      {super.key, required this.headers, required this.bodies});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            children: headers,
          ),
          ...bodies,
        ],
      ),
    );
  }
}
