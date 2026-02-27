import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_app/models/membership.dart';

class MembershipCard extends StatelessWidget {
  final Membership? membership;
  final VoidCallback onRenew;

  const MembershipCard({
    super.key,
    required this.membership,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_membership, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Абонемент',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (membership != null) ...[
            _buildInfoRow(
              'Действителен до:',
              dateFormat.format(membership!.expiryDate),
            ),
            _buildInfoRow(
              'Осталось дней:',
              '${membership!.daysLeft}',
              color: membership!.daysLeft < 7 ? Colors.orange : Colors.green,
            ),
          ] else ...[
            const Text(
              'Абонемент не оформлен',
              style: TextStyle(color: Colors.grey),
            ),
          ],
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRenew,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                membership != null ? 'Продлить абонемент' : 'Оформить абонемент',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}