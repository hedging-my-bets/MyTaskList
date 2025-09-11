import React, { useState, useEffect } from 'react';
import { View, StyleSheet, ScrollView, Switch, TouchableOpacity, Alert } from 'react-native';
import { ThemedText } from '../components/ThemedText';
import { ThemedView } from '../components/ThemedView';
import { TimePickerModal } from '../components/TimePickerModal';
import { TaskService } from '../services/TaskService';
import { DailyCloseoutService } from '../services/DailyCloseoutService';
import { AppSettings } from '../types';
import { formatTime } from '../utils/dateUtils';

export function SettingsScreen() {
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [showTimeModal, setShowTimeModal] = useState(false);
  const [showGraceModal, setShowGraceModal] = useState(false);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const currentSettings = await TaskService.getSettings();
      setSettings(currentSettings);
    } catch (error) {
      console.error('Error loading settings:', error);
      Alert.alert('Error', 'Failed to load settings');
    } finally {
      setLoading(false);
    }
  };

  const saveSettings = async (newSettings: AppSettings) => {
    try {
      await TaskService.saveSettings(newSettings);
      setSettings(newSettings);
    } catch (error) {
      console.error('Error saving settings:', error);
      Alert.alert('Error', 'Failed to save settings');
    }
  };

  const handleResetTimeChange = () => {
    setShowTimeModal(true);
  };

  const handleTimeModalSave = (timeString: string) => {
    if (!settings) return;
    
    const [hourStr, minuteStr] = timeString.split(':');
    const hour = parseInt(hourStr, 10);
    const minute = parseInt(minuteStr, 10);
    
    saveSettings({
      ...settings,
      resetTime: { hour, minute }
    });
    setShowTimeModal(false);
  };

  const validateTimeFormat = (timeString: string): boolean => {
    const [hourStr, minuteStr] = timeString.split(':');
    const hour = parseInt(hourStr, 10);
    const minute = parseInt(minuteStr, 10);
    
    return (
      !isNaN(hour) && 
      !isNaN(minute) && 
      hour >= 0 && hour <= 23 && 
      minute >= 0 && minute <= 59
    );
  };

  const handleGraceWindowChange = () => {
    setShowGraceModal(true);
  };

  const handleGraceModalSave = (minutesString: string) => {
    if (!settings) return;
    
    const minutes = parseInt(minutesString, 10);
    saveSettings({
      ...settings,
      graceWindow: minutes
    });
    setShowGraceModal(false);
  };

  const validateGraceWindow = (minutesString: string): boolean => {
    const minutes = parseInt(minutesString, 10);
    return !isNaN(minutes) && minutes >= 0 && minutes <= 180;
  };

  const handleRolloverToggle = (enabled: boolean) => {
    if (!settings) return;
    saveSettings({
      ...settings,
      rolloverEnabled: enabled
    });
  };

  const handleHapticsToggle = (enabled: boolean) => {
    if (!settings) return;
    saveSettings({
      ...settings,
      hapticsEnabled: enabled
    });
  };

  const handleForceCloseout = () => {
    Alert.alert(
      'Force Daily Closeout',
      'This will immediately run the daily closeout process. This may affect your pet\'s evolution. Are you sure?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Run Closeout',
          style: 'destructive',
          onPress: async () => {
            try {
              await DailyCloseoutService.forceCloseout();
              Alert.alert('Success', 'Daily closeout completed');
            } catch (error) {
              console.error('Error running closeout:', error);
              Alert.alert('Error', 'Failed to run closeout');
            }
          }
        }
      ]
    );
  };

  const handleResetData = () => {
    Alert.alert(
      'Reset All Data',
      'This will delete ALL tasks and reset your pet to stage 1. This cannot be undone!',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reset All Data',
          style: 'destructive',
          onPress: () => {
            Alert.alert(
              'Final Confirmation',
              'Are you absolutely sure? This will permanently delete everything!',
              [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'DELETE EVERYTHING',
                  style: 'destructive',
                  onPress: async () => {
                    try {
                      await TaskService.resetAllData();
                      Alert.alert('Success', 'All data has been reset. Pet returned to stage 1 and all tasks cleared.');
                      loadSettings(); // Reload settings to show defaults
                    } catch (error) {
                      console.error('Error resetting data:', error);
                      Alert.alert('Error', 'Failed to reset data');
                    }
                  }
                }
              ]
            );
          }
        }
      ]
    );
  };

  if (loading || !settings) {
    return (
      <ThemedView style={styles.container}>
        <ThemedText style={styles.loadingText}>Loading...</ThemedText>
      </ThemedView>
    );
  }

  return (
    <ThemedView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        
        {/* General Settings */}
        <View style={styles.section}>
          <ThemedText style={styles.sectionTitle}>General</ThemedText>
          
          <TouchableOpacity style={styles.settingRow} onPress={handleResetTimeChange}>
            <View style={styles.settingInfo}>
              <ThemedText style={styles.settingLabel}>Reset Time</ThemedText>
              <ThemedText style={styles.settingDescription}>
                When the day resets and closeout occurs
              </ThemedText>
            </View>
            <ThemedText style={styles.settingValue}>
              {formatTime(settings.resetTime.hour, settings.resetTime.minute)}
            </ThemedText>
          </TouchableOpacity>

          <TouchableOpacity style={styles.settingRow} onPress={handleGraceWindowChange}>
            <View style={styles.settingInfo}>
              <ThemedText style={styles.settingLabel}>Grace Window</ThemedText>
              <ThemedText style={styles.settingDescription}>
                Minutes early/late that still count as "on time"
              </ThemedText>
            </View>
            <ThemedText style={styles.settingValue}>
              ±{settings.graceWindow}m
            </ThemedText>
          </TouchableOpacity>
        </View>

        {/* Task Settings */}
        <View style={styles.section}>
          <ThemedText style={styles.sectionTitle}>Tasks</ThemedText>
          
          <View style={styles.settingRow}>
            <View style={styles.settingInfo}>
              <ThemedText style={styles.settingLabel}>Rollover Tasks</ThemedText>
              <ThemedText style={styles.settingDescription}>
                Carry incomplete tasks to tomorrow
              </ThemedText>
            </View>
            <Switch
              value={settings.rolloverEnabled}
              onValueChange={handleRolloverToggle}
            />
          </View>
        </View>

        {/* App Settings */}
        <View style={styles.section}>
          <ThemedText style={styles.sectionTitle}>App</ThemedText>
          
          <View style={styles.settingRow}>
            <View style={styles.settingInfo}>
              <ThemedText style={styles.settingLabel}>Haptic Feedback</ThemedText>
              <ThemedText style={styles.settingDescription}>
                Vibrate on task completion
              </ThemedText>
            </View>
            <Switch
              value={settings.hapticsEnabled}
              onValueChange={handleHapticsToggle}
            />
          </View>
        </View>

        {/* Debug/Admin */}
        <View style={styles.section}>
          <ThemedText style={styles.sectionTitle}>Debug</ThemedText>
          
          <TouchableOpacity 
            style={[styles.settingRow, styles.dangerRow]} 
            onPress={handleForceCloseout}
          >
            <View style={styles.settingInfo}>
              <ThemedText style={[styles.settingLabel, styles.dangerText]}>
                Force Daily Closeout
              </ThemedText>
              <ThemedText style={styles.settingDescription}>
                Manually trigger closeout for previous day
              </ThemedText>
            </View>
          </TouchableOpacity>

          <TouchableOpacity 
            style={[styles.settingRow, styles.dangerRow]} 
            onPress={handleResetData}
          >
            <View style={styles.settingInfo}>
              <ThemedText style={[styles.settingLabel, styles.dangerText]}>
                Reset All Data
              </ThemedText>
              <ThemedText style={styles.settingDescription}>
                Delete all tasks and reset pet to stage 1
              </ThemedText>
            </View>
          </TouchableOpacity>
        </View>

        <View style={styles.bottomPadding} />
      </ScrollView>

      {/* Time Input Modal */}
      <TimePickerModal
        visible={showTimeModal}
        title="Set Reset Time"
        currentValue={settings ? formatTime(settings.resetTime.hour, settings.resetTime.minute) : '00:00'}
        placeholder="HH:MM (24-hour format)"
        onSave={handleTimeModalSave}
        onCancel={() => setShowTimeModal(false)}
        validator={validateTimeFormat}
        errorMessage="Please enter time in HH:MM format (00:00 to 23:59)"
      />

      {/* Grace Window Modal */}
      <TimePickerModal
        visible={showGraceModal}
        title="Set Grace Window"
        currentValue={settings ? settings.graceWindow.toString() : '60'}
        placeholder="Minutes (0-180)"
        onSave={handleGraceModalSave}
        onCancel={() => setShowGraceModal(false)}
        validator={validateGraceWindow}
        errorMessage="Please enter a number between 0 and 180"
      />
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  loadingText: {
    textAlign: 'center',
    fontSize: 18,
    marginTop: 50,
  },
  section: {
    marginVertical: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 12,
    marginHorizontal: 16,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E0E0E0',
  },
  settingInfo: {
    flex: 1,
  },
  settingLabel: {
    fontSize: 16,
    fontWeight: '500',
    marginBottom: 2,
  },
  settingDescription: {
    fontSize: 14,
    color: '#666666',
  },
  settingValue: {
    fontSize: 16,
    color: '#2196F3',
    fontWeight: '500',
  },
  dangerRow: {
    borderBottomColor: '#FFEBEE',
  },
  dangerText: {
    color: '#F44336',
  },
  bottomPadding: {
    height: 40,
  },
});