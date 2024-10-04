import 'package:flutter/material.dart';

class ArrayInput extends StatefulWidget {
  final List<String>? initial;
  final String itemName;
  final double maxHeight;
  final void Function(List<String>)? onChanged;
  const ArrayInput(
      {super.key,
      this.initial,
      required this.itemName,
      required this.onChanged,
      this.maxHeight = double.infinity});

  @override
  State<ArrayInput> createState() => _ArrayInputState();
}

class _ArrayInputState extends State<ArrayInput> {
  Set<String> selected = {};
  bool isInputMode = false;
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selected.addAll(widget.initial ?? []);
  }

  void _scrollDown() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(seconds: 1000),
              curve: Curves.easeOut,
            ));
  }

  void _addItem() {
    String value = controller.text;
    if (selected.contains(value)) {
      return;
    }
    setState(() {
      selected.add(value);
      isInputMode = false;
      controller.text = '';
      if (widget.onChanged != null) {
        widget.onChanged!(selected.toList());
      }
      _scrollDown();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected.isNotEmpty)
            Flexible(
              child: ListView(
                primary: false,
                shrinkWrap: true,
                controller: scrollController,
                children: selected
                    .map(
                      (e) => ListTile(
                        title: Text(e),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              selected.remove(e);
                              if (widget.onChanged != null) {
                                widget.onChanged!(selected.toList());
                              }
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          (isInputMode)
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                            label: Text('Press enter to add new')),
                        onSubmitted: (String value) {
                          _addItem();
                        },
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          _addItem();
                        },
                        child: Text('Add ${widget.itemName}'))
                  ],
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      isInputMode = true;
                    });
                  },
                  label: Text('Add ${widget.itemName}'),
                  icon: const Icon(Icons.add),
                ),
        ],
      ),
    );
  }
}
