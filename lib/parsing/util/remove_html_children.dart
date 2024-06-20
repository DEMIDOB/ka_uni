removeHtmlChildren(element) {
  element.children.forEach((child) {
    child.remove();
  });
}