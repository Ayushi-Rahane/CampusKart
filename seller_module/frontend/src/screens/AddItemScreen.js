import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, ActivityIndicator, Alert, KeyboardAvoidingView, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Camera, Image as ImageIcon, Send, ArrowLeft } from 'lucide-react-native';
import * as ImagePicker from 'expo-image-picker';
import apiClient from '../api/client';
import { theme } from '../theme';

const AddItemScreen = ({ navigation }) => {
  const [form, setForm] = useState({ title: '', description: '', price: '', category: 'Electronics' });
  const [image, setImage] = useState(null);
  const [loading, setLoading] = useState(false);

  const pickImage = async () => {
    let result = await ImagePicker.launchImageLibraryAsync({ allowsEditing: true, aspect: [4, 3], quality: 1 });
    if (!result.canceled) setImage(result.assets[0].uri);
  };

  const handleSubmit = async () => {
    if (!form.title || !form.price || !image) {
      Alert.alert('Error', 'Please fill all fields and add a photo.');
      return;
    }
    setLoading(true);
    const formData = new FormData();
    formData.append('title', form.title);
    formData.append('description', form.description);
    formData.append('price', form.price);
    formData.append('category', form.category);
    formData.append('image', { uri: image, name: 'photo.jpg', type: 'image/jpeg' });

    try {
      await apiClient.post('/items', formData, { headers: { 'Content-Type': 'multipart/form-data' } });
      Alert.alert('Success', 'Listed on CampusCart!');
      navigation.goBack();
    } catch (error) {
      Alert.alert('Error', 'Listing failed.');
    } finally { setLoading(false); }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={{ flex: 1, backgroundColor: theme.colors.background }}>
      <ScrollView contentContainerStyle={{ paddingBottom: 50 }}>
        <LinearGradient colors={theme.colors.loginGradient} style={styles.header}>
            <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
                <ArrowLeft size={24} color="#fff" />
            </TouchableOpacity>
            <Text style={styles.headerTitle}>List Your Item</Text>
            <Text style={styles.headerSubtitle}>Sell to your fellow students</Text>
        </LinearGradient>

        <View style={styles.content}>
          <TouchableOpacity style={styles.photoUpload} onPress={pickImage}>
            {image ? (
              <Text style={styles.photoText}>Photo Added ✅</Text>
            ) : (
              <View style={{ alignItems: 'center' }}>
                <Camera size={32} color={theme.colors.accentTeal} />
                <Text style={styles.photoText}>Add Product Photo</Text>
              </View>
            )}
          </TouchableOpacity>

          <Text style={styles.label}>Item Name</Text>
          <TextInput style={styles.input} placeholder="What are you selling?" value={form.title} onChangeText={(t) => setForm({...form, title: t})} />

          <Text style={styles.label}>Price (₹)</Text>
          <TextInput style={styles.input} placeholder="Set a fair price" keyboardType="numeric" value={form.price} onChangeText={(t) => setForm({...form, price: t})} />

          <Text style={styles.label}>Description</Text>
          <TextInput style={[styles.input, { height: 100, textAlignVertical: 'top', borderRadius: 15 }]} placeholder="Describe condition, age, etc." multiline value={form.description} onChangeText={(t) => setForm({...form, description: t})} />

          <TouchableOpacity style={styles.submitBtn} onPress={handleSubmit} disabled={loading}>
            {loading ? <ActivityIndicator color="#fff" /> : (
              <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                <Send size={18} color="#fff" style={{ marginRight: 10 }} />
                <Text style={styles.submitBtnText}>Post Listing</Text>
              </View>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  header: { height: 160, justifyContent: 'center', paddingHorizontal: 25, borderBottomLeftRadius: 30, borderBottomRightRadius: 30, paddingTop: 20 },
  backBtn: { marginBottom: 10 },
  headerTitle: { fontSize: 26, fontWeight: 'bold', color: '#fff' },
  headerSubtitle: { fontSize: 14, color: '#fff', opacity: 0.8 },
  content: { padding: 25 },
  photoUpload: { height: 150, backgroundColor: '#fff', borderRadius: 20, borderStyle: 'dashed', borderWidth: 2, borderColor: theme.colors.accentTeal, justifyContent: 'center', alignItems: 'center', marginBottom: 25 },
  photoText: { marginTop: 10, color: theme.colors.textLight, fontWeight: '500' },
  label: { fontSize: 14, fontWeight: 'bold', color: theme.colors.text, marginBottom: 8, marginLeft: 5 },
  input: { backgroundColor: '#fff', borderRadius: theme.borderRadius.input, padding: 15, fontSize: 15, marginBottom: 20, borderWidth: 1, borderColor: '#eee' },
  submitBtn: { backgroundColor: theme.colors.primary, borderRadius: theme.borderRadius.pill, height: 55, justifyContent: 'center', alignItems: 'center', marginTop: 10, ...theme.colors.cardShadow },
  submitBtnText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
});

export default AddItemScreen;
