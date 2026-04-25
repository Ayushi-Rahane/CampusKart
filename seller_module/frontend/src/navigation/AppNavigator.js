import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Home, PlusSquare, User } from 'lucide-react-native';
import { theme } from '../theme';

// Screens
import LoginScreen from '../screens/LoginScreen';
import AddItemScreen from '../screens/AddItemScreen';
import MyListingsScreen from '../screens/MyListingsScreen';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();

const MainTabs = () => {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ color }) => {
          let Icon;
          if (route.name === 'My Listings') Icon = Home;
          else if (route.name === 'Sell') Icon = PlusSquare;
          return <Icon size={24} color={color} />;
        },
        tabBarActiveTintColor: theme.colors.primary,
        tabBarInactiveTintColor: theme.colors.textLight,
        headerShown: false,
      })}
    >
      <Tab.Screen name="My Listings" component={MyListingsScreen} />
      <Tab.Screen name="Sell" component={AddItemScreen} />
    </Tab.Navigator>
  );
};

const AppNavigator = () => {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="MainTabs" component={MainTabs} />
    </Stack.Navigator>
  );
};

export default AppNavigator;
