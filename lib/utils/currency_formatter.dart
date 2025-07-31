String _formatAmount(double amount) {
  return '₹${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)}';
}
