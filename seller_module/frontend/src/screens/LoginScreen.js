import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform, ActivityIndicator, Alert } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { User, Lock, ArrowRight } from 'lucide-react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import apiClient from '../api/client';
import { theme } from '../theme';

const LoginScreen = ({ navigation }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    if (!email || !password) {
      Alert.alert('Error', 'Please enter email and password');
      return;
    }
    setLoading(true);
    try {
      const { data } = await apiClient.post('/auth/login', { email, password });
      await AsyncStorage.setItem('userToken', data.token);
      navigation.navigate('MainTabs');
    } catch (error) {
      Alert.alert('Login Failed', 'Invalid credentials');
    } finally {
      setLoading(false);
    }
  };

  return (
    <LinearGradient colors={theme.colors.loginGradient} style={styles.container}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.content}>
        <View style={styles.logoArea}>
            <View style={styles.logoIcon}><Text style={{ fontSize: 40 }}>🌿</Text></View>
            <Text style={styles.title}>CampusCart</Text>
            <Text style={styles.subtitle}>Student Marketplace</Text>
        </View>

        <View style={styles.form}>
            <View style={styles.inputGroup}>
                <User size={20} color={theme.colors.accentTeal} style={styles.inputIcon} />
                <TextInput 
                    style={styles.input} 
                    placeholder="Campus Email" 
                    placeholderTextColor="#AEE1E1"
                    value={email}
                    onChangeText={setEmail}
                    autoCapitalize="none"
                />
            </View>

            <View style={styles.inputGroup}>
                <Lock size={20} color={theme.colors.accentTeal} style={styles.inputIcon} />
                <TextInput 
                    style={styles.input} 
                    placeholder="Password" 
                    placeholderTextColor="#AEE1E1"
                    secureTextEntry
                    value={password}
                    onChangeText={setPassword}
                />
            </View>

            <TouchableOpacity style={styles.loginBtn} onPress={handleLogin} disabled={loading}>
                {loading ? <ActivityIndicator color="#fff" /> : (
                    <>
                        <Text style={styles.loginBtnText}>Login</Text>
                        <ArrowRight size={20} color="#fff" />
                    </>
                )}
            </TouchableOpacity>

            <TouchableOpacity style={styles.signupLink}>
                <Text style={styles.signupText}>Don't have an account? <Text style={{ fontWeight: 'bold', color: theme.colors.secondary }}>Sign Up</Text></Text>
            </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </LinearGradient>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { flex: 1, justifyContent: 'center', padding: 30 },
  logoArea: { alignItems: 'center', marginBottom: 50 },
  logoIcon: { width: 80, height: 80, backgroundColor: '#fff', borderRadius: 20, justifyContent: 'center', alignItems: 'center', marginBottom: 15 },
  title: { fontSize: 32, fontWeight: 'bold', color: '#fff' },
  subtitle: { fontSize: 16, color: '#AEE1E1', marginTop: 5 },
  form: { width: '100%' },
  inputGroup: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: theme.borderRadius.pill, paddingHorizontal: 20, marginBottom: 20, borderSize: 1, borderColor: 'rgba(255,255,255,0.2)' },
  inputIcon: { marginRight: 10 },
  input: { flex: 1, height: 55, color: '#fff', fontSize: 16 },
  loginBtn: { backgroundColor: theme.colors.primary, height: 55, borderRadius: theme.borderRadius.pill, flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 10, gap: 10 },
  loginBtnText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  signupLink: { marginTop: 25, alignItems: 'center' },
  signupText: { color: '#fff', fontSize: 14 }
});

export default LoginScreen;
