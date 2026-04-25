import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, FlatList, Image, TouchableOpacity, StyleSheet, ActivityIndicator, Alert, Dimensions } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Edit3, Trash2, CheckCircle, Package, ArrowLeft } from 'lucide-react-native';
import apiClient from '../api/client';
import { theme } from '../theme';

const MyListingsScreen = ({ navigation }) => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchMyItems = async () => {
    try {
      const response = await apiClient.get('/items/my');
      setItems(response.data);
    } catch (error) {
      Alert.alert('Error', 'Could not load your items');
    } finally {
      setLoading(false);
    }
  };

  useFocusEffect(useCallback(() => { fetchMyItems(); }, []));

  const handleDelete = async (id) => {
    Alert.alert('Delete', 'Remove this listing permanently?', [
      { text: 'Cancel' },
      { text: 'Delete', style: 'destructive', onPress: async () => {
          await apiClient.delete(`/items/${id}`);
          fetchMyItems();
      }}
    ]);
  };

  const markSold = async (id) => {
    await apiClient.patch(`/items/${id}/sold`);
    fetchMyItems();
  };

  const renderItem = ({ item }) => (
    <View style={styles.card}>
      <Image source={{ uri: item.imageUrl }} style={styles.image} />
      <View style={styles.info}>
        <View>
          <Text style={styles.title} numberOfLines={1}>{item.title}</Text>
          <Text style={styles.price}>₹{item.price}</Text>
          <View style={[styles.statusBadge, { backgroundColor: item.status === 'sold' ? '#FFE5E5' : '#E5F6ED' }]}>
            <Text style={[styles.statusText, { color: item.status === 'sold' ? theme.colors.primary : '#4CAF50' }]}>
              {item.status.toUpperCase()}
            </Text>
          </View>
        </View>

        <View style={styles.actions}>
          <TouchableOpacity style={styles.actionBtn} onPress={() => navigation.navigate('Edit Item', { item })}>
            <Edit3 size={18} color={theme.colors.textLight} />
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionBtn} onPress={() => handleDelete(item._id)}>
            <Trash2 size={18} color={theme.colors.primary} />
          </TouchableOpacity>

          {item.status === 'available' && (
            <TouchableOpacity style={styles.soldBtn} onPress={() => markSold(item._id)}>
              <CheckCircle size={16} color="#fff" />
              <Text style={styles.soldBtnText}>Sold</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <ArrowLeft size={28} color={theme.colors.text} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>My Listings</Text>
        <Package size={28} color={theme.colors.primary} />
      </View>

      {loading ? (
        <ActivityIndicator size="large" color={theme.colors.primary} style={{ marginTop: 50 }} />
      ) : (
        <FlatList
          data={items}
          keyExtractor={(item) => item._id}
          renderItem={renderItem}
          contentContainerStyle={{ paddingBottom: 100 }}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyText}>Nothing listed yet.</Text>
              <TouchableOpacity style={styles.startBtn} onPress={() => navigation.navigate('Sell')}>
                <Text style={styles.startBtnText}>Sell Something</Text>
              </TouchableOpacity>
            </View>
          }
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background, paddingHorizontal: 20 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 50, marginBottom: 25 },
  headerTitle: { fontSize: 26, fontWeight: 'bold', color: theme.colors.text },
  card: { backgroundColor: '#fff', borderRadius: 20, marginBottom: 15, flexDirection: 'row', padding: 12, ...theme.colors.cardShadow },
  image: { width: 90, height: 90, borderRadius: 15 },
  info: { flex: 1, marginLeft: 15, justifyContent: 'space-between' },
  title: { fontSize: 18, fontWeight: 'bold', color: theme.colors.text },
  price: { fontSize: 16, color: theme.colors.primary, fontWeight: '700', marginTop: 2 },
  statusBadge: { alignSelf: 'flex-start', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 10, marginTop: 5 },
  statusText: { fontSize: 10, fontWeight: 'bold' },
  actions: { flexDirection: 'row', alignItems: 'center', marginTop: 10 },
  actionBtn: { padding: 8, backgroundColor: '#F8F8F8', borderRadius: 10, marginRight: 10 },
  soldBtn: { backgroundColor: '#4CAF50', flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, borderRadius: 10, height: 35 },
  soldBtnText: { color: '#fff', fontSize: 12, fontWeight: 'bold', marginLeft: 5 },
  emptyContainer: { alignItems: 'center', marginTop: 100 },
  emptyText: { fontSize: 16, color: theme.colors.textLight, marginBottom: 20 },
  startBtn: { backgroundColor: theme.colors.primary, paddingHorizontal: 30, paddingVertical: 12, borderRadius: theme.borderRadius.pill },
  startBtnText: { color: '#fff', fontWeight: 'bold' }
});

export default MyListingsScreen;
