import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:ta_pos/view-model-flutter/transaksi_controller.dart';
import 'package:intl/intl.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  @override
  _DeliveryHistoryScreenState createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  List<dynamic> _deliveries = [];
  dynamic _selectedDelivery;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    final deliveries = await showallDelivery(context);
    if (deliveries != null) {
      setState(() {
        _deliveries = deliveries;
      });
    }
  }

  void _selectDelivery(dynamic delivery) {
    setState(() {
      _selectedDelivery = delivery;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery List'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildDeliveryHistory(),
          ),
          Expanded(
            flex: 3,
            child: _selectedDelivery != null
                ? DetailSection(delivery: _selectedDelivery)
                : Center(child: Text('Select a delivery for details')),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryHistory() {
    return ListView.builder(
      itemCount: _deliveries.length,
      itemBuilder: (context, index) {
        final delivery = _deliveries[index];
        return ListTile(
          title: Text(
            delivery['alamat_tujuan'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Status: ${delivery['status']}'),
          onTap: () => _selectDelivery(delivery),
        );
      },
    );
  }
}

class DetailSection extends StatelessWidget {
  final dynamic delivery;

  DetailSection({required this.delivery});

  String formatDeliveryTime(DateTime deliveryTime) {
    // Convert the time to WIB (UTC+7)
    DateTime ZoneTime = deliveryTime.toUtc().add(const Duration(hours: 7));

    // Format the time as Day, Time, and Date (e.g., Monday, 14:30, October 23, 2024)
    String formattedTime =
        DateFormat('EEEE, HH:mm, MMMM dd, yyyy').format(ZoneTime);

    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    String formatted = "";
    if (delivery['deliver_time'] != null) {
      DateTime deliveryTime = DateTime.parse(delivery['deliver_time']);
      formatted = formatDeliveryTime(deliveryTime);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Delivery ID: ${delivery['_id']}'),
          Text('Address: ${delivery['alamat_tujuan']}'),
          Text('Customer Phone: ${delivery['no_telp_cust']}'),
          Text('Transaction ID: ${delivery['transaksi_id']}'),
          Text('Status: ${delivery['status']}'),
          delivery['deliver_time'] != null
              ? Text('Delivery Time: $formatted')
              : Text('Delivery Time: Not yet delivered'),
          SizedBox(height: 16),
          delivery['bukti_pengiriman'] != null
              ? Image.memory(
                  base64Decode(delivery['bukti_pengiriman']),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : Text('No proof of delivery available'),
        ],
      ),
    );
  }
}
