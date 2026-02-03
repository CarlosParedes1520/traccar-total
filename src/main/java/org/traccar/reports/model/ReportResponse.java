package org.traccar.reports.model;

import java.util.Collection;

public class ReportResponse<T> {

    private long totalPages;
    private long currentPage;
    private int pageSize;
    private long totalItems;
    private Collection<T> items;

    public ReportResponse(Collection<T> items, long totalItems, int pageSize, long offset) {
        this.items = items;
        this.totalItems = totalItems;
        this.pageSize = pageSize;
        this.currentPage = pageSize > 0 ? (offset / pageSize) + 1 : 1;
        this.totalPages = pageSize > 0 ? (long) Math.ceil((double) totalItems / pageSize) : 1;
    }

    public long getTotalPages() {
        return totalPages;
    }

    public void setTotalPages(long totalPages) {
        this.totalPages = totalPages;
    }

    public long getCurrentPage() {
        return currentPage;
    }

    public void setCurrentPage(long currentPage) {
        this.currentPage = currentPage;
    }

    public int getPageSize() {
        return pageSize;
    }

    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }

    public long getTotalItems() {
        return totalItems;
    }

    public void setTotalItems(long totalItems) {
        this.totalItems = totalItems;
    }

    public Collection<T> getItems() {
        return items;
    }

    public void setItems(Collection<T> items) {
        this.items = items;
    }
}
