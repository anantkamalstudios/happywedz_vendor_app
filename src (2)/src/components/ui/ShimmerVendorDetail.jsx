import React from "react";

/**
 * Skeleton placeholder for the vendor detail page (Detailed.jsx).
 * Mirrors the real layout — breadcrumb, gallery + thumbnails on the left,
 * info card on the right, tabs and about text below — so the page does not
 * visually jump once the vendor API responds.
 */
const ShimmerVendorDetail = () => {
  return (
    <div className="svd-shimmer" role="status" aria-label="Loading vendor details">
      <span className="visually-hidden">Loading vendor details...</span>

      {/* Breadcrumb */}
      <div className="svd-breadcrumb">
        <span className="svd-box svd-crumb" />
        <span className="svd-box svd-crumb" />
        <span className="svd-box svd-crumb" />
        <span className="svd-box svd-crumb svd-crumb-wide" />
      </div>

      <div className="svd-grid">
        {/* Left: gallery */}
        <div className="svd-left">
          <div className="svd-box svd-gallery" />
          <div className="svd-thumbs">
            <div className="svd-box svd-thumb" />
            <div className="svd-box svd-thumb" />
            <div className="svd-box svd-thumb" />
            <div className="svd-box svd-thumb" />
          </div>
        </div>

        {/* Right: info card */}
        <aside className="svd-card">
          <div className="svd-box svd-heading" />
          <div className="svd-box svd-line" />
          <div className="svd-box svd-line svd-line-80" />
          <div className="svd-box svd-line svd-line-50" />
          <div className="svd-box svd-pill" />

          <div className="svd-divider" />

          <div className="svd-box svd-label" />
          <div className="svd-box svd-line svd-line-80" />

          <div className="svd-box svd-label" />
          <div className="svd-box svd-line svd-line-50" />

          <div className="svd-box svd-btn" />
          <div className="svd-box svd-btn" />
        </aside>
      </div>

      {/* Tabs */}
      <div className="svd-tabs">
        <span className="svd-box svd-tab" />
        <span className="svd-box svd-tab" />
        <span className="svd-box svd-tab" />
        <span className="svd-box svd-tab" />
      </div>

      {/* About */}
      <div className="svd-about">
        <div className="svd-box svd-heading svd-heading-sm" />
        <div className="svd-box svd-line" />
        <div className="svd-box svd-line" />
        <div className="svd-box svd-line svd-line-80" />
        <div className="svd-box svd-line svd-line-50" />
      </div>
    </div>
  );
};

export default ShimmerVendorDetail;
