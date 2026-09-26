import { useState, useEffect } from "react";
import {
  FaCheck,
  FaPlus,
  FaDownload,
  FaPrint,
  FaCalendarAlt,
  FaHeart,
  FaTimes,
} from "react-icons/fa";
import { FiCheck, FiTrash, FiLink, FiEdit, FiClock } from "react-icons/fi";
import { FaChevronDown, FaSpinner } from "react-icons/fa6";
import axiosInstance from "../../../../services/api/axiosInstance";
import axios from "axios";
import { useSelector } from "react-redux";
import { Link } from "react-router-dom";
import Swal from "sweetalert2";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import dayjs from "dayjs";
import { pdf } from "@react-pdf/renderer";
import ChecklistPDF from "./ChecklistPDF";
import { formatDate } from "../../../../utils/dateFormat";
import { Dropdown } from "react-bootstrap";
import "./Checklist.css";

const CATEGORY_API =
  "https://happywedz.com/api/vendor-types/with-subcategories/all";

const Check = () => {
  const user = useSelector((state) => state.auth.user);
  const token = useSelector((state) => state.auth.token);
  const userId = user?.id || user?.user_id || user?._id;

  const [checklists, setChecklists] = useState([]);
  const [text, setText] = useState("");
  const [vendorSubId, setVendorSubId] = useState("");
  const [categories, setCategories] = useState([]);
  const [startDate, setStartDate] = useState("");
  // Initialize wedding date from Redux user data
  const [weddingDate, setWeddingDate] = useState(
    user?.weddingDate ? String(user.weddingDate).slice(0, 10) : ""
  );
  const [loading, setLoading] = useState(false);

  // Handler for start date change
  const handleStartDateChange = (newDate) => {
    const formattedDate = newDate ? dayjs(newDate).format("YYYY-MM-DD") : "";
    setStartDate(formattedDate);
  };

  // Handler for wedding date change
  const handleWeddingDateChange = (newDate) => {
    const formattedDate = newDate ? dayjs(newDate).format("YYYY-MM-DD") : "";
    setWeddingDate(formattedDate);
  };
  const [refresh, setRefresh] = useState(false);
  const [error, setError] = useState(null);
  const [daysLeft, setDaysLeft] = useState(null);
  const [requiredDays, setRequiredDays] = useState(0);
  const [timeOptions, setTimeOptions] = useState([]);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;
  const [editingId, setEditingId] = useState(null);
  const [editingText, setEditingText] = useState("");
  const [updateLoading, setUpdateLoading] = useState(false);

  const fetchChecklists = async () => {
    if (!userId || !token) return;
    setLoading(true);
    try {
      const res = await axiosInstance.get(
        `/new-checklist/newChecklist/user/${userId}`
      );
      const fetchedChecklists = res.data?.data || [];
      setChecklists(fetchedChecklists);
      if (res.data?.data?.length > 0) {
        const firstTask = res.data.data[0];
        if (firstTask.start_date)
          setStartDate(firstTask.start_date.split("T")[0]);
        if (firstTask.wedding_date)
          setWeddingDate(firstTask.wedding_date.split("T")[0]);
      }
    } catch (err) {
      console.error("Error fetching checklists:", err);
      setError("Failed to load checklist data");
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const res = await axios.get(CATEGORY_API);
      const allSubs = res.data.flatMap((cat) =>
        cat.subcategories.map((sub) => ({
          id: sub.id,
          name: sub.name,
          required_days: sub.required_days || 2,
          category: { id: cat.id, name: cat.name },
        }))
      );
      setCategories(allSubs);
    } catch (err) {
      console.error("Error fetching categories:", err);
    }
  };

  // Sync wedding date from Redux when user data changes
  useEffect(() => {
    if (user?.weddingDate) {
      const formattedDate = String(user.weddingDate).slice(0, 10);
      setWeddingDate(formattedDate);
    }
  }, [user?.weddingDate]);

  const [countdown, setCountdown] = useState(null);

  useEffect(() => {
    if (!weddingDate) {
      setDaysLeft(null);
      setCountdown(null);
      return;
    }

    const calculateCountdown = () => {
      const now = new Date();
      const target = new Date(weddingDate);
      const diff = target.getTime() - now.getTime();

      if (diff > 0) {
        const days = Math.floor(diff / (1000 * 60 * 60 * 24));
        const hours = Math.floor(
          (diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
        );
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((diff % (1000 * 60)) / 1000);
        setDaysLeft(days);
        setCountdown({ days, hours, minutes, seconds, hasPassed: false });
      } else {
        const diffDays = Math.ceil(Math.abs(diff) / (1000 * 60 * 60 * 24));
        setDaysLeft(-diffDays);
        setCountdown({
          days: diffDays,
          hours: 0,
          minutes: 0,
          seconds: 0,
          hasPassed: true,
        });
      }
    };

    calculateCountdown();
    const timer = setInterval(calculateCountdown, 1000);
    return () => clearInterval(timer);
  }, [weddingDate]);

  useEffect(() => {
    fetchChecklists();
    fetchCategories();
  }, [userId, refresh]);

  useEffect(() => {
    if (vendorSubId && categories.length) {
      const selected = categories.find((c) => c.id === parseInt(vendorSubId));
      setRequiredDays(selected?.required_days || 0);
    }
  }, [vendorSubId, categories]);

  useEffect(() => {
    if (startDate && weddingDate && requiredDays > 0) {
      const s = new Date(startDate);
      const w = new Date(weddingDate);
      const totalDays = Math.ceil((w - s) / (1000 * 60 * 60 * 24));

      if (totalDays < 8) {
        setTimeOptions(["Wedding too near (<8 days)"]);
        return;
      }

      const endDate = new Date(s);
      endDate.setDate(endDate.getDate() + requiredDays);

      setTimeOptions([
        `${requiredDays} days required`,
        `Start: ${formatDate(s)}`,
        `End: ${formatDate(endDate)}`,
        `Remaining buffer: ${totalDays - requiredDays} days`,
      ]);
    }
  }, [startDate, weddingDate, requiredDays]);

  const [distributedTasks, setDistributedTasks] = useState([]);

  useEffect(() => {
    if (!startDate || !weddingDate || checklists.length === 0) {
      setDistributedTasks([]);
      return;
    }

    const start = new Date(startDate);
    const end = new Date(weddingDate);
    const totalDays = Math.max(
      1,
      Math.ceil((end - start) / (1000 * 60 * 60 * 24))
    );
    const perTaskDays = Math.max(1, Math.floor(totalDays / checklists.length));

    const temp = [];
    let current = new Date(start);

    for (let i = 0; i < checklists.length; i++) {
      const taskStart = new Date(current);
      const taskEnd = new Date(current);
      taskEnd.setDate(taskEnd.getDate() + perTaskDays - 1);
      temp.push({
        ...checklists[i],
        days_assigned: perTaskDays,
        distributed_start_date: formatDate(taskStart),
        distributed_end_date: formatDate(taskEnd),
      });
      current.setDate(current.getDate() + perTaskDays);
    }
    setDistributedTasks(temp);
  }, [checklists, startDate, weddingDate]);

  const addChecklist = async () => {
    setError(null);

    if (!text || !vendorSubId) {
      setError("Please fill all fields before adding a task.");
      return;
    }

    if (!startDate || !weddingDate) {
      setError("Please select start and wedding dates first.");
      return;
    }

    const sDate = new Date(startDate);
    const wDate = new Date(weddingDate);
    if (wDate < sDate) {
      setError("Wedding date cannot be before start date.");
      return;
    }

    const today = new Date();
    const wedding = new Date(weddingDate);
    const diffDays = Math.ceil((wedding - today) / (1000 * 60 * 60 * 24));

    if (diffDays < 8) {
      setError(
        "Your wedding is near! Checklist cannot be created (less than 8 days left)."
      );
      return;
    }

    const payload = {
      userId,
      vendor_subcategory_id: vendorSubId,
      text,
      start_date: startDate,
      wedding_date: weddingDate,
      status: "pending",
    };

    try {
      await axiosInstance.post(`/new-checklist/create`, payload);
      setText("");
      setVendorSubId("");
      setRefresh((prev) => !prev);
    } catch (err) {
      console.error("Error adding checklist:", err);
      setError("Failed to create checklist.");
    }
  };

  const handleEdit = (id, currentText) => {
    setEditingId(id);
    setEditingText(currentText);
  };

  const saveEdit = async () => {
    if (!editingText.trim()) {
      setError("Task name cannot be empty.");
      return;
    }

    setUpdateLoading(true);
    try {
      await axiosInstance.put(`/new-checklist/update/${editingId}`, {
        text: editingText,
      });
      setEditingId(null);
      setEditingText("");
      setRefresh((prev) => !prev);
    } catch (err) {
      console.error("Error updating checklist:", err);
      setError("Failed to update task.");
    } finally {
      setUpdateLoading(false);
    }
  };

  const cancelEdit = () => {
    setEditingId(null);
    setEditingText("");
  };

  const toggleStatus = async (id, currentStatus) => {
    try {
      const newStatus = currentStatus === "completed" ? "pending" : "completed";
      await axiosInstance.put(`/new-checklist/update/${id}`, {
        status: newStatus,
      });
      setRefresh((prev) => !prev);
    } catch (err) {
      setError("Failed to update checklist.");
    }
  };

  const deleteChecklist = async (id) => {
    try {
      await axiosInstance.delete(`/new-checklist/delete/${id}`);
      setRefresh((prev) => !prev);
    } catch (err) {
      setError("Failed to delete checklist.");
    }
  };

  const handleDownloadPDF = async () => {
    const itemsToDownload =
      Array.isArray(distributedTasks) && distributedTasks.length > 0
        ? distributedTasks
        : Array.isArray(checklists)
          ? checklists
          : [];

    if (itemsToDownload.length === 0) {
      Swal.fire({
        icon: "info",
        text: "No tasks to download.",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }

    try {
      Swal.fire({
        title: "Generating PDF...",
        allowOutsideClick: false,
        didOpen: () => {
          Swal.showLoading();
        },
      });

      const doc = (
        <ChecklistPDF
          items={itemsToDownload}
          categories={Array.isArray(categories) ? categories : []}
          meta={{
            userName: user?.name || user?.email || "User",
            generatedAt: new Date(),
          }}
        />
      );

      const asPdf = pdf(doc);
      const blob = await asPdf.toBlob();

      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", `checklist-${userId || "user"}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);

      Swal.close();
      Swal.fire({
        icon: "success",
        text: "Checklist downloaded successfully!",
        timer: 2000,
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
    } catch (err) {
      console.error("Download Error:", err);
      Swal.close();
      Swal.fire({
        icon: "error",
        text: "Could not download the checklist. Please try again.",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
    }
  };

  const completedCount = checklists.filter(
    (c) => c.status === "completed"
  ).length;
  const progressPercentage =
    checklists.length > 0 ? (completedCount / checklists.length) * 100 : 0;

  const currentTasks =
    distributedTasks.length > 0 ? distributedTasks : checklists;
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = currentTasks.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(currentTasks.length / itemsPerPage);
  const paginate = (pageNumber) => setCurrentPage(pageNumber);

  return (
    <>
      <div className="checklist-container">
        <div className="container">
          <div className="row">
            {/* Sidebar */}
            <div className="col-lg-4 mb-4">
              <div className="stat-card border border-black">
                <div className="stat-card-header fs-16">
                  <FiClock size={20} />
                  <span>Task Status</span>
                </div>
                <div className="status-item d-flex justify-content-between align-items-center fs-14">
                  <span style={{ fontWeight: "600", color: "#374151" }}>
                    Pending Tasks
                  </span>
                  <span className="status-badge text-danger">
                    {checklists.filter((c) => c.status === "pending").length}
                  </span>
                </div>
                <div className="status-item d-flex justify-content-between align-items-center fs-14">
                  <span style={{ fontWeight: "600", color: "#374151" }}>
                    Completed Tasks
                  </span>
                  <span className="status-badge">{completedCount}</span>
                </div>
              </div>

              {/* Wedding Dates Card */}
              <div className="stat-card border border-black">
                <div className="stat-card-header fs-16">
                  <FaCalendarAlt size={18} />
                  <span>Wedding Timeline</span>
                </div>
                <div className="date-input-group fs-16">
                  <label>
                    <FaCalendarAlt size={14} />
                    Start Date
                  </label>
                  <LocalizationProvider
                    className="fs-14"
                    dateAdapter={AdapterDayjs}
                  >
                    <DatePicker
                      value={startDate ? dayjs(startDate) : null}
                      format="DD/MM/YYYY"
                      onChange={handleStartDateChange}
                      className="fs-14"
                      disabled={checklists.length > 0 && !!startDate}
                      slotProps={{
                        textField: {
                          fullWidth: true,
                          size: "small",
                          placeholder: "Select start date",
                          className: "fs-14",
                          InputProps: { style: { fontSize: 14 } },
                          inputProps: { style: { fontSize: 14 } },
                        },
                      }}
                    />
                  </LocalizationProvider>
                </div>
                <div className="date-input-group fs-14">
                  <label>
                    <FaHeart size={14} />
                    Wedding Date
                  </label>
                  <LocalizationProvider dateAdapter={AdapterDayjs}>
                    <DatePicker
                      value={weddingDate ? dayjs(weddingDate) : null}
                      format="DD/MM/YYYY"
                      onChange={handleWeddingDateChange}
                      disabled={checklists.length > 0 && !!weddingDate}
                      slotProps={{
                        textField: {
                          fullWidth: true,
                          size: "small",
                          placeholder: "Select wedding date",
                          InputProps: { style: { fontSize: 14 } },
                          inputProps: { style: { fontSize: 14 } },
                        },
                      }}
                    />
                  </LocalizationProvider>
                </div>

                {countdown && (
                  <div className="hw-countdown-card">
                    <div className="hw-countdown-header">
                      <FaHeart className="hw-countdown-icon" />
                      <span className="hw-countdown-title">
                        {countdown.hasPassed
                          ? "Wedding Milestone"
                          : "Countdown to The Big Day"}
                      </span>
                    </div>

                    {!countdown.hasPassed ? (
                      <div className="hw-countdown-grid">
                        <div className="hw-countdown-box">
                          <div className="hw-countdown-num">
                            {String(countdown.days).padStart(2, "0")}
                          </div>
                          <div className="hw-countdown-unit">DAYS</div>
                        </div>
                        <div className="hw-countdown-colon">:</div>
                        <div className="hw-countdown-box">
                          <div className="hw-countdown-num">
                            {String(countdown.hours).padStart(2, "0")}
                          </div>
                          <div className="hw-countdown-unit">HOURS</div>
                        </div>
                        <div className="hw-countdown-colon">:</div>
                        <div className="hw-countdown-box">
                          <div className="hw-countdown-num">
                            {String(countdown.minutes).padStart(2, "0")}
                          </div>
                          <div className="hw-countdown-unit">MINS</div>
                        </div>
                        <div className="hw-countdown-colon">:</div>
                        <div className="hw-countdown-box">
                          <div className="hw-countdown-num">
                            {String(countdown.seconds).padStart(2, "0")}
                          </div>
                          <div className="hw-countdown-unit">SECS</div>
                        </div>
                      </div>
                    ) : (
                      <div className="hw-countdown-grid">
                        <div className="hw-countdown-box" style={{ minWidth: "120px" }}>
                          <div className="hw-countdown-num" style={{ color: "#ed1173" }}>
                            {countdown.days}
                          </div>
                          <div className="hw-countdown-unit">DAYS AGO</div>
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Main Content */}
            <div className="col-lg-8">
              <div className="hw-checklist-container">
                <div className="hw-checklist-header">
                  <h5 className="hw-checklist-title">
                    <FaHeart />
                    Wedding Checklist & Planning Tasks
                  </h5>
                  <div className="d-flex gap-2">
                    {(distributedTasks && distributedTasks.length > 0) ||
                      (checklists && checklists.length > 0) ? (
                      <button
                        className="hw-download-btn"
                        onClick={handleDownloadPDF}
                      >
                        <FaDownload size={12} />
                        Download PDF
                      </button>
                    ) : (
                      <button
                        className="hw-download-btn"
                        disabled
                        title="No tasks to download"
                      >
                        <FaDownload size={12} />
                        Download PDF
                      </button>
                    )}
                  </div>
                </div>

                <div className="p-4">
                  {/* Overall Progress Card */}
                  <div className="hw-progress-card">
                    <div className="hw-progress-header">
                      <h6 className="hw-progress-title">Overall Task Completion</h6>
                      <span className="hw-progress-badge">
                        {Math.round(progressPercentage)}% Complete
                      </span>
                    </div>
                    <div className="hw-progress-track">
                      <div
                        className="hw-progress-fill"
                        style={{ width: `${progressPercentage}%` }}
                      />
                    </div>
                    <div className="hw-progress-stats">
                      <div className="hw-stat-pill">
                        <span className="hw-stat-num" style={{ color: "#10b981" }}>{completedCount}</span>
                        <span className="hw-stat-label">Tasks Completed</span>
                      </div>
                      <div className="hw-stat-pill">
                        <span className="hw-stat-num" style={{ color: "#0f172a" }}>{checklists.length}</span>
                        <span className="hw-stat-label">Total Tasks</span>
                      </div>
                      <div className="hw-stat-pill">
                        <span className="hw-stat-num" style={{ color: "#ed1173" }}>{Math.max(0, checklists.length - completedCount)}</span>
                        <span className="hw-stat-label">Tasks Remaining</span>
                      </div>
                    </div>
                  </div>

                  {error && (
                    <div
                      className="alert alert-danger alert-custom alert-dismissible fade show fs-14 fw-bold mb-4"
                      role="alert"
                    >
                      {error}
                      <button
                        type="button"
                        className="btn-close"
                        onClick={() => setError(null)}
                      />
                    </div>
                  )}

                  {/* Add Task Form */}
                  <div className="hw-add-task-card">
                    <div className="hw-add-task-header">
                      <FaPlus style={{ color: "#ed1173", fontSize: "14px" }} />
                      <h6 className="hw-add-task-title">Add New Task</h6>
                    </div>
                    <div className="row align-items-end g-3">
                      <div className="col-12 col-md-5">
                        <label className="hw-form-label">Vendor Category</label>
                        <Dropdown drop="down" autoClose="outside">
                          <Dropdown.Toggle className="hw-dropdown-toggle">
                            <span>
                              {vendorSubId
                                ? categories.find((c) => c.id == vendorSubId)?.name
                                : "Select Vendor Category"}
                            </span>
                            <FaChevronDown size={11} style={{ color: "#94a3b8" }} />
                          </Dropdown.Toggle>

                          <Dropdown.Menu
                            className="w-100 shadow-lg border-0"
                            style={{
                              maxHeight: "220px",
                              overflowY: "auto",
                              borderRadius: "12px",
                              padding: "6px",
                              zIndex: 9999,
                            }}
                          >
                            {categories.map((sub) => (
                              <Dropdown.Item
                                key={sub.id}
                                onClick={() => setVendorSubId(sub.id)}
                                style={{
                                  borderRadius: "8px",
                                  fontSize: "13.5px",
                                  fontWeight: "500",
                                  padding: "8px 12px",
                                }}
                              >
                                {sub.name}
                              </Dropdown.Item>
                            ))}
                          </Dropdown.Menu>
                        </Dropdown>
                      </div>

                      <div className="col-12 col-md-5">
                        <label className="hw-form-label">Task Description</label>
                        <input
                          type="text"
                          className="hw-input"
                          placeholder="e.g., Shortlist & Book Photographer"
                          value={text}
                          onChange={(e) => setText(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === "Enter") addChecklist();
                          }}
                        />
                      </div>

                      <div className="col-12 col-md-2">
                        <button
                          className="hw-btn-add w-100"
                          onClick={addChecklist}
                        >
                          <FaPlus size={12} />
                          <span>Add Task</span>
                        </button>
                      </div>
                    </div>

                    {timeOptions.length > 0 && (
                      <div className="time-info mt-3">
                        <label>⏱ Estimated Time Allocation</label>
                        <ul>
                          {timeOptions.map((t, i) => (
                            <li key={i}>{t}</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>

                  {loading ? (
                    <div className="text-center py-5">
                      <div
                        className="spinner-border spinner-custom"
                        role="status"
                      >
                        <span className="visually-hidden">Loading...</span>
                      </div>
                    </div>
                  ) : checklists.length > 0 ? (
                    <>
                      <div className="hw-table-card">
                        <div className="table-responsive">
                          <table className="hw-task-table">
                            <thead>
                              <tr>
                                <th style={{ width: "90px", textAlign: "center" }}>Status</th>
                                <th>Task Details</th>
                                <th>Category & Lead Time</th>
                                <th style={{ width: "170px" }}>Allocated Timeline</th>
                                <th style={{ width: "110px", textAlign: "center" }}>Actions</th>
                              </tr>
                            </thead>
                            <tbody>
                              {currentItems.map((item) => (
                                <tr key={item.id}>
                                  <td className="text-center">
                                    <div
                                      className={`hw-status-toggle ${
                                        item.status === "completed" ? "is-completed" : ""
                                      }`}
                                      onClick={() =>
                                        toggleStatus(item.id, item.status)
                                      }
                                      title={
                                        item.status === "completed"
                                          ? "Click to mark as pending"
                                          : "Click to mark as completed"
                                      }
                                    >
                                      {item.status === "completed" ? (
                                        <FaCheck size={13} />
                                      ) : (
                                        <FiCheck size={14} />
                                      )}
                                    </div>
                                  </td>
                                  <td>
                                    {editingId === item.id ? (
                                      <input
                                        type="text"
                                        className="form-control form-control-sm"
                                        value={editingText}
                                        onChange={(e) =>
                                          setEditingText(e.target.value)
                                        }
                                        autoFocus
                                      />
                                    ) : (
                                      <span
                                        className={`hw-task-name ${
                                          item.status === "completed"
                                            ? "is-completed"
                                            : ""
                                        }`}
                                      >
                                        {item.text}
                                      </span>
                                    )}
                                  </td>
                                  <td>
                                    {(() => {
                                      const subcategory = categories.find(
                                        (c) => c.id === item.vendor_subcategory_id
                                      );
                                      return (
                                        <div className="hw-category-wrapper">
                                          <span className="hw-category-title">
                                            {subcategory?.name || "General"}
                                          </span>
                                          {subcategory?.required_days && (
                                            <span
                                              className="hw-lead-time-badge"
                                              title="Estimated preparation/lead time required"
                                            >
                                              <FiClock size={11} />
                                              ~{subcategory.required_days}d prep
                                            </span>
                                          )}
                                        </div>
                                      );
                                    })()}
                                  </td>
                                  <td>
                                    <span
                                      className="hw-timeline-badge"
                                      title="Days allocated in your wedding planning schedule"
                                    >
                                      <FaCalendarAlt size={11} style={{ color: "#3b82f6" }} />
                                      {item.days_assigned || "—"}{" "}
                                      {item.days_assigned ? "Days Allocated" : ""}
                                    </span>
                                  </td>
                                  <td>
                                    <div className="d-flex gap-2 justify-content-center">
                                      {editingId === item.id ? (
                                        <>
                                          <button
                                            className="hw-action-btn"
                                            style={{
                                              background: "#ecfdf5",
                                              color: "#059669",
                                              borderColor: "#a7f3d0",
                                            }}
                                            onClick={saveEdit}
                                            disabled={updateLoading}
                                            title="Save Changes"
                                          >
                                            {updateLoading ? (
                                              <FaSpinner
                                                className="spin"
                                                size={13}
                                              />
                                            ) : (
                                              <FaCheck size={13} />
                                            )}
                                          </button>

                                          <button
                                            className="hw-action-btn"
                                            style={{
                                              background: "#f1f5f9",
                                              color: "#64748b",
                                            }}
                                            onClick={cancelEdit}
                                            disabled={updateLoading}
                                            title="Cancel"
                                          >
                                            <FaTimes size={13} />
                                          </button>
                                        </>
                                      ) : (
                                        <>
                                          <button
                                            className="hw-action-btn edit-btn"
                                            onClick={() =>
                                              handleEdit(item.id, item.text)
                                            }
                                            title="Edit Task"
                                          >
                                            <FiEdit size={14} />
                                          </button>
                                          <button
                                            className="hw-action-btn delete-btn"
                                            onClick={() =>
                                              deleteChecklist(item.id)
                                            }
                                            title="Delete Task"
                                          >
                                            <FiTrash size={14} />
                                          </button>
                                        </>
                                      )}
                                    </div>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>

                      {totalPages > 1 && (
                        <nav>
                          <ul className="pagination justify-content-center">
                            {Array.from({ length: totalPages }, (_, i) => (
                              <li
                                key={i + 1}
                                className={`page-item ${currentPage === i + 1 ? "active" : ""
                                  }`}
                              >
                                <button
                                  onClick={() => paginate(i + 1)}
                                  className="page-link"
                                >
                                  {i + 1}
                                </button>
                              </li>
                            ))}
                          </ul>
                        </nav>
                      )}
                    </>
                  ) : (
                    <div className="empty-state text-center py-4">
                      <img
                        src="/images/userDashboard/no-task-available.png"
                        alt="No tasks"
                        style={{
                          width: "100%",
                          maxWidth: "220px",
                          opacity: 0.7,
                        }}
                      />
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Check;
