'use client';

import { useState, useRef, type FormEvent } from 'react';
import {
  CameraAlt,
  PhotoCamera,
  Facebook,
  Twitter,
  LinkedIn,
  YouTube,
  Language,
  Link as LinkIcon,
} from '@mui/icons-material';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { Validators } from '../../lib/validators';
import {
  AppBackButton,
  AppButton,
  AppTextField,
  PhoneInputField,
  ResponsiveDialog,
} from '../../components/ui';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

export default function EditProfilePage() {
  const pageRef = usePageTransition();
  const { lang, profile, user, refreshAuth } = useApp();

  const isInstructor = profile?.role === 'instructor';

  const [name, setName] = useState(profile?.name || '');
  const [phone, setPhone] = useState(profile?.phone || '');
  const [countryCode, setCountryCode] = useState('+20');
  const [displayName, setDisplayName] = useState('');
  const [headlineAr, setHeadlineAr] = useState('');
  const [headlineEn, setHeadlineEn] = useState('');
  const [bioAr, setBioAr] = useState('');
  const [bioEn, setBioEn] = useState('');
  const [expertise, setExpertise] = useState('');
  const [website, setWebsite] = useState('');
  const [facebook, setFacebook] = useState('');
  const [twitter, setTwitter] = useState('');
  const [linkedin, setLinkedin] = useState('');
  const [youtube, setYoutube] = useState('');

  const [avatarUrl, setAvatarUrl] = useState(profile?.avatar_url || '');
  const [coverUrl, setCoverUrl] = useState('');
  const [uploadingAvatar, setUploadingAvatar] = useState(false);
  const [uploadingCover, setUploadingCover] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [confirmOpen, setConfirmOpen] = useState(false);

  const avatarInputRef = useRef<HTMLInputElement>(null);
  const coverInputRef = useRef<HTMLInputElement>(null);

  const l = lang === 'ar';

  const getInitials = (nameStr?: string) => {
    if (!nameStr) return '?';
    const parts = nameStr.trim().split(/\s+/);
    if (parts.length === 1) return parts[0][0];
    return parts[0][0] + parts[parts.length - 1][0];
  };

  const uploadImage = async (file: File, bucket: string): Promise<string | null> => {
    if (!user) return null;
    const ext = file.name.split('.').pop();
    const path = `${user.id}/${Date.now()}.${ext}`;
    const { error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(path, file, { upsert: true });
    if (uploadError) {
      console.error('Upload error:', uploadError);
      return null;
    }
    const { data } = supabase.storage.from(bucket).getPublicUrl(path);
    return data.publicUrl;
  };

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingAvatar(true);
    const url = await uploadImage(file, 'avatars');
    if (url) setAvatarUrl(url);
    setUploadingAvatar(false);
  };

  const handleCoverChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingCover(true);
    const url = await uploadImage(file, 'avatars');
    if (url) setCoverUrl(url);
    setUploadingCover(false);
  };

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};
    const nameError = Validators.name(name, { lang });
    if (nameError) newErrors.name = nameError;
    if (phone) {
      const phoneError = Validators.phone(phone, { lang });
      if (phoneError) newErrors.phone = phoneError;
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validate() || !user) return;
    setSaving(true);
    try {
      const updates: Record<string, unknown> = {
        name,
        phone: `${countryCode}${phone}`,
        avatar_url: avatarUrl,
      };
      if (isInstructor) {
        updates.display_name = displayName;
        updates.headline_ar = headlineAr;
        updates.headline_en = headlineEn;
        updates.bio_ar = bioAr;
        updates.bio_en = bioEn;
        updates.expertise = expertise;
        updates.website = website;
        updates.facebook = facebook;
        updates.twitter = twitter;
        updates.linkedin = linkedin;
        updates.youtube = youtube;
        if (coverUrl) updates.cover_url = coverUrl;
      }
      const { error } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.id);
      if (error) throw error;
      await refreshAuth();
      setConfirmOpen(true);
    } catch (err) {
      console.error('Save error:', err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.topBar}>
        <AppBackButton />
        <span className={styles.topBarTitle}>
          {l ? 'تعديل الملف الشخصي' : 'Edit Profile'}
        </span>
        <AppButton
          variant="primary"
          size="small"
          loading={saving}
          onClick={handleSave}
          disabled={uploadingAvatar || uploadingCover}
        >
          {l ? 'حفظ' : 'Save'}
        </AppButton>
      </div>

      <div className={styles.avatarSection}>
        <div className={styles.avatarWrapper}>
          {avatarUrl ? (
            <img className={styles.avatarImage} src={avatarUrl} alt={name} />
          ) : (
            <span className={styles.avatarInitials}>{getInitials(name)}</span>
          )}
          <button
            className={styles.cameraOverlay}
            onClick={() => avatarInputRef.current?.click()}
            type="button"
            aria-label={l ? 'تغيير الصورة' : 'Change avatar'}
          >
            <CameraAlt fontSize="small" />
          </button>
          <input
            ref={avatarInputRef}
            type="file"
            accept="image/*"
            hidden
            onChange={handleAvatarChange}
          />
        </div>
        <span
          className={styles.changeAvatarText}
          onClick={() => avatarInputRef.current?.click()}
        >
          {uploadingAvatar
            ? (l ? 'جاري الرفع...' : 'Uploading...')
            : (l ? 'تغيير الصورة' : 'Change Avatar')}
        </span>
      </div>

      {isInstructor && (
        <div className={styles.coverSection}>
          <span className={styles.coverLabel}>
            {l ? 'صورة الغلاف' : 'Cover Image'}
          </span>
          <div
            className={styles.coverPlaceholder}
            onClick={() => coverInputRef.current?.click()}
          >
            {coverUrl ? (
              <img src={coverUrl} alt="Cover" />
            ) : (
              <>
                <PhotoCamera className={styles.coverIcon} />
                <span className={styles.coverText}>
                  {uploadingCover
                    ? (l ? 'جاري الرفع...' : 'Uploading...')
                    : (l ? 'اختر صورة الغلاف' : 'Choose cover image')}
                </span>
              </>
            )}
          </div>
          <input
            ref={coverInputRef}
            type="file"
            accept="image/*"
            hidden
            onChange={handleCoverChange}
          />
        </div>
      )}

      <div className={styles.formSection}>
        <h2 className={styles.formTitle}>
          {l ? 'المعلومات الشخصية' : 'Personal Information'}
        </h2>
        <div className={styles.fields}>
          <AppTextField
            label={l ? 'الاسم' : 'Name'}
            value={name}
            onChange={(e) => setName(e.target.value)}
            error={errors.name}
            required
            name="name"
            id="name"
          />
          <PhoneInputField
            label={l ? 'رقم الهاتف' : 'Phone Number'}
            value={phone}
            onChange={setPhone}
            countryCode={countryCode}
            onCountryCodeChange={setCountryCode}
            error={errors.phone}
            placeholder={l ? '01XXXXXXXXX' : '01XXXXXXXXX'}
          />
        </div>
      </div>

      {isInstructor && (
        <div className={styles.formSection}>
          <h2 className={styles.formTitle}>
            {l ? 'بيانات المدرس' : 'Instructor Details'}
            <span className={styles.instructorBadge}>
              {l ? 'مدرس' : 'Instructor'}
            </span>
          </h2>
          <div className={styles.fields}>
            <AppTextField
              label={l ? 'الاسم المعروض' : 'Display Name'}
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              name="displayName"
              id="displayName"
            />
            <AppTextField
              label={l ? 'العنوان (عربي)' : 'Headline (Arabic)'}
              value={headlineAr}
              onChange={(e) => setHeadlineAr(e.target.value)}
              name="headlineAr"
              id="headlineAr"
            />
            <AppTextField
              label={l ? 'العنوان (إنجليزي)' : 'Headline (English)'}
              value={headlineEn}
              onChange={(e) => setHeadlineEn(e.target.value)}
              name="headlineEn"
              id="headlineEn"
            />
            <AppTextField
              label={l ? 'نبذة (عربي)' : 'Bio (Arabic)'}
              value={bioAr}
              onChange={(e) => setBioAr(e.target.value)}
              multiline
              rows={3}
              name="bioAr"
              id="bioAr"
            />
            <AppTextField
              label={l ? 'نبذة (إنجليزي)' : 'Bio (English)'}
              value={bioEn}
              onChange={(e) => setBioEn(e.target.value)}
              multiline
              rows={3}
              name="bioEn"
              id="bioEn"
            />
            <AppTextField
              label={l ? 'التخصص' : 'Expertise'}
              value={expertise}
              onChange={(e) => setExpertise(e.target.value)}
              name="expertise"
              id="expertise"
            />
            <AppTextField
              label={l ? 'الموقع الإلكتروني' : 'Website'}
              value={website}
              onChange={(e) => setWebsite(e.target.value)}
              prefixIcon={<Language fontSize="small" />}
              name="website"
              id="website"
            />
            <div className={styles.divider} />
            <h3 className={styles.formTitle}>
              {l ? 'روابط التواصل' : 'Social Links'}
            </h3>
            <div className={styles.socialLinksGrid}>
              <AppTextField
                label="Facebook"
                value={facebook}
                onChange={(e) => setFacebook(e.target.value)}
                prefixIcon={<Facebook fontSize="small" />}
                name="facebook"
                id="facebook"
              />
              <AppTextField
                label="Twitter / X"
                value={twitter}
                onChange={(e) => setTwitter(e.target.value)}
                prefixIcon={<Twitter fontSize="small" />}
                name="twitter"
                id="twitter"
              />
              <AppTextField
                label="LinkedIn"
                value={linkedin}
                onChange={(e) => setLinkedin(e.target.value)}
                prefixIcon={<LinkedIn fontSize="small" />}
                name="linkedin"
                id="linkedin"
              />
              <AppTextField
                label="YouTube"
                value={youtube}
                onChange={(e) => setYoutube(e.target.value)}
                prefixIcon={<YouTube fontSize="small" />}
                name="youtube"
                id="youtube"
              />
            </div>
          </div>
        </div>
      )}

      <div className={styles.saveSection}>
        <AppButton
          variant="primary"
          fullWidth
          size="large"
          loading={saving}
          onClick={handleSave}
          disabled={uploadingAvatar || uploadingCover}
        >
          {saving
            ? (l ? 'جاري الحفظ...' : 'Saving...')
            : (l ? 'حفظ التغييرات' : 'Save Changes')}
        </AppButton>
      </div>

      <ResponsiveDialog
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        title={l ? 'تم الحفظ' : 'Saved'}
        actions={
          <AppButton
            variant="primary"
            onClick={() => setConfirmOpen(false)}
          >
            {l ? 'تم' : 'OK'}
          </AppButton>
        }
      >
        {l ? 'تم حفظ بياناتك بنجاح' : 'Your profile has been updated successfully'}
      </ResponsiveDialog>
    </main>
  );
}
