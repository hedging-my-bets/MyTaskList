import React, { useState } from 'react';
import { View, StyleSheet, Modal, TouchableOpacity, TextInput } from 'react-native';
import { ThemedText } from './ThemedText';

interface TimePickerModalProps {
  visible: boolean;
  title: string;
  currentValue: string;
  placeholder: string;
  onSave: (value: string) => void;
  onCancel: () => void;
  validator?: (value: string) => boolean;
  errorMessage?: string;
}

/**
 * Cross-platform modal for time/number input (replaces Alert.prompt)
 */
export function TimePickerModal({ 
  visible, 
  title, 
  currentValue, 
  placeholder,
  onSave, 
  onCancel,
  validator,
  errorMessage = 'Invalid input'
}: TimePickerModalProps) {
  const [inputValue, setInputValue] = useState(currentValue);
  const [showError, setShowError] = useState(false);

  const handleSave = () => {
    if (validator && !validator(inputValue)) {
      setShowError(true);
      return;
    }
    
    setShowError(false);
    onSave(inputValue);
    setInputValue(currentValue); // Reset on save
  };

  const handleCancel = () => {
    setShowError(false);
    setInputValue(currentValue); // Reset to original value
    onCancel();
  };

  return (
    <Modal
      visible={visible}
      transparent={true}
      animationType="fade"
      onRequestClose={handleCancel}
    >
      <View style={styles.overlay}>
        <View style={styles.modal}>
          <ThemedText style={styles.title}>{title}</ThemedText>
          
          <TextInput
            style={[styles.input, showError && styles.inputError]}
            value={inputValue}
            onChangeText={(text) => {
              setInputValue(text);
              setShowError(false);
            }}
            placeholder={placeholder}
            placeholderTextColor="#999999"
            autoFocus={true}
          />
          
          {showError && (
            <ThemedText style={styles.errorText}>{errorMessage}</ThemedText>
          )}
          
          <View style={styles.buttons}>
            <TouchableOpacity style={styles.button} onPress={handleCancel}>
              <ThemedText style={styles.cancelButtonText}>Cancel</ThemedText>
            </TouchableOpacity>
            
            <TouchableOpacity style={[styles.button, styles.saveButton]} onPress={handleSave}>
              <ThemedText style={styles.saveButtonText}>Save</ThemedText>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modal: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 20,
    width: '80%',
    maxWidth: 300,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
    marginBottom: 16,
  },
  input: {
    borderWidth: 1,
    borderColor: '#E0E0E0',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 8,
  },
  inputError: {
    borderColor: '#F44336',
  },
  errorText: {
    color: '#F44336',
    fontSize: 14,
    marginBottom: 16,
  },
  buttons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 16,
  },
  button: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    marginHorizontal: 4,
  },
  saveButton: {
    backgroundColor: '#2196F3',
  },
  cancelButtonText: {
    textAlign: 'center',
    fontSize: 16,
    color: '#666666',
  },
  saveButtonText: {
    textAlign: 'center',
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
  },
});